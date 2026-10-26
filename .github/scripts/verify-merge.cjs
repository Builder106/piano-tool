const {setTimeout} = require('node:timers/promises');

module.exports = async function verifyMerge({github, context, core, wait = setTimeout}) {
  const run = context.payload.workflow_run;
  const repo = context.repo;
  const fullName = `${repo.owner}/${repo.repo}`;
  const branch = context.payload.repository.default_branch;
  if (run.event !== 'pull_request' || run.conclusion !== 'success' ||
      run.head_repository?.full_name !== fullName) return;

  const {data: candidates} = await github.rest.repos.listPullRequestsAssociatedWithCommit({
    ...repo, commit_sha: run.head_sha, per_page: 100,
  });
  const candidate = candidates.find(pr => pr.base.ref === branch &&
    pr.head.repo?.full_name === fullName && pr.head.sha === run.head_sha);
  if (!candidate) return;

  let pr;
  for (let attempt = 0; attempt < 12; attempt++) {
    ({data: pr} = await github.rest.pulls.get({...repo, pull_number: candidate.number}));
    if (pr.head.sha !== run.head_sha || pr.base.ref !== branch ||
        pr.head.repo?.full_name !== fullName) return;
    if (pr.merged) break;
    if (pr.state !== 'open' || !pr.auto_merge) return;
    await wait(5000);
  }
  if (!pr.merged) throw new Error(`PR #${pr.number} has not merged after CI completed.`);

  const {data: main} = await github.rest.git.getRef({...repo, ref: `heads/${branch}`});
  if (main.object.sha !== pr.merge_commit_sha) {
    core.info('A newer commit is on the default branch; its CI handles deployment.');
    return;
  }
  const {data: runs} = await github.rest.actions.listWorkflowRuns({
    ...repo, workflow_id: 'ci.yml', head_sha: pr.merge_commit_sha, per_page: 100,
  });
  if (runs.workflow_runs.some(item => ['push', 'workflow_dispatch'].includes(item.event))) {
    core.info('The merge already has a default-branch CI run.');
    return;
  }
  await github.rest.actions.createWorkflowDispatch({...repo, workflow_id: 'ci.yml', ref: branch});
  core.info(`Requested default-branch CI for merged PR #${pr.number}.`);
};
