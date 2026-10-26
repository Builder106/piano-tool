const assert = require('node:assert/strict');
const {test} = require('node:test');
const verifyMerge = require('./verify-merge.cjs');

function harness() {
  const pr = {
    number: 26, state: 'closed', merged: true, merge_commit_sha: 'merged',
    head: {sha: 'tested', repo: {full_name: 'Builder106/piano-tool'}},
    base: {ref: 'main'},
  };
  const state = {pr, main: 'merged', runs: [], dispatched: [], reads: 0};
  const context = {
    repo: {owner: 'Builder106', repo: 'piano-tool'},
    payload: {
      repository: {default_branch: 'main'},
      workflow_run: {
        event: 'pull_request', conclusion: 'success', head_sha: 'tested',
        head_repository: {full_name: 'Builder106/piano-tool'},
      },
    },
  };
  const github = {rest: {
    repos: {listPullRequestsAssociatedWithCommit: async () => ({data: [pr]})},
    pulls: {get: async () => { state.reads++; return {data: state.pr}; }},
    git: {getRef: async () => ({data: {object: {sha: state.main}}})},
    actions: {
      listWorkflowRuns: async () => ({data: {workflow_runs: state.runs}}),
      createWorkflowDispatch: async args => { state.dispatched.push(args); },
    },
  }};
  const args = {github, context, core: {info() {}}, wait: async () => {}};
  return {state, args};
}

test('a bot merge without a push run requests CI on main', async () => {
  const {state, args} = harness();
  await verifyMerge(args);
  assert.deepEqual(state.dispatched, [{
    owner: 'Builder106', repo: 'piano-tool', workflow_id: 'ci.yml', ref: 'main',
  }]);
});

for (const event of ['push', 'workflow_dispatch']) {
  test(`an existing ${event} run prevents a duplicate dispatch`, async () => {
    const {state, args} = harness();
    state.runs = [{event}];
    await verifyMerge(args);
    assert.equal(state.dispatched.length, 0);
  });
}

for (const scenario of ['failed', 'fork', 'foreign-pr', 'retargeted', 'stale', 'new-main', 'unmerged', 'manual', 'dispatch']) {
  test(`${scenario} input cannot request production CI`, async () => {
    const {state, args} = harness();
    if (scenario === 'failed') args.context.payload.workflow_run.conclusion = 'failure';
    if (scenario === 'fork') args.context.payload.workflow_run.head_repository.full_name = 'someone/fork';
    if (scenario === 'foreign-pr') state.pr.head.repo.full_name = 'someone/fork';
    if (scenario === 'retargeted') state.pr.base.ref = 'another-branch';
    if (scenario === 'stale') state.pr.head.sha = 'new-head';
    if (scenario === 'new-main') state.main = 'newer';
    if (scenario === 'unmerged') state.pr.merged = false;
    if (scenario === 'manual') state.pr = {...state.pr, merged: false, state: 'open'};
    if (scenario === 'dispatch') args.context.payload.workflow_run.event = 'workflow_dispatch';
    await verifyMerge(args);
    assert.equal(state.dispatched.length, 0);
  });
}

test('a PR updated after candidate lookup cannot dispatch CI', async () => {
  const {state, args} = harness();
  state.pr = {...state.pr, head: {...state.pr.head, sha: 'new-head'}};
  await verifyMerge(args);
  assert.equal(state.dispatched.length, 0);
});

test('waits for auto-merge after the final CI result', async () => {
  const {state, args} = harness();
  state.pr = {...state.pr, merged: false, state: 'open', auto_merge: {}};
  args.wait = async () => { state.pr = {...state.pr, merged: true}; };
  await verifyMerge(args);
  assert.equal(state.reads, 2);
  assert.equal(state.dispatched.length, 1);
});

test('a merge timeout fails visibly without dispatching', async () => {
  const {state, args} = harness();
  state.pr = {...state.pr, merged: false, state: 'open', auto_merge: {}};
  await assert.rejects(verifyMerge(args), /has not merged/);
  assert.equal(state.dispatched.length, 0);
});
