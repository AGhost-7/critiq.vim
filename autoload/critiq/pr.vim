
" Contains generic functions to perform various API calls

fu! s:call_provider(function_name, args)
	" TODO: determine provider through tab local variable?
	let provider_name = 'github'
	return critiq#providers#github#request(a:function_name, a:args)
endfu

fu! critiq#pr#list_open_prs(repos, page, options, callback)
	return s:call_provider('list_open_prs', [
		\ a:repos,
		\ a:page,
		\ a:options,
		\ a:callback,
		\ ])
endfu

fu! critiq#pr#pull_request(issue, callback)
	return s:call_provider('pull_request', [a:issue, a:callback])
endfu

fu! critiq#pr#diff(issue, callback)
	return s:call_provider('diff', [a:issue, a:callback])
endfu

fu! critiq#pr#submit_review(pr, event, body)
	return s:call_provider('submit_review', [a:pr, a:event, a:body])
endfu

fu! critiq#pr#submit_comment(pr, line, body)
	return s:call_provider('submit_comment', [a:pr, a:line, a:body])
endfu

fu! critiq#pr#merge_pr(pr)
	return s:call_provider('merge_pr', [a:pr])
endfu

fu! critiq#pr#browse_pr(pr)
	return s:call_provider('browse_pr', [a:pr])
endfu

fu! critiq#pr#pr_comments(issue, callback)
	return s:call_provider('pr_comments', [a:issue, a:callback])
endfu

fu! critiq#pr#checkout(pr)
	return s:call_provider('checkout', [a:pr])
endfu

fu! critiq#pr#pull(pr)
	return s:call_provider('pull', [a:pr])
endfu

fu! critiq#pr#repo_labels(issue, callback)
	return s:call_provider('repo_labels', [a:issue, a:callback])
endfu

fu! critiq#pr#toggle_label(pr, repo_labels, pr_labels, label_index, callback)
	return s:call_provider('toggle_label', [a:pr, a:repo_labels, a:pr_labels, a:label_index, a:callback])
endfu

fu! critiq#pr#pr_reviews(issue, callback)
	return s:call_provider('pr_reviews', [a:issue, a:callback])
endfu

fu! critiq#pr#delete_branch(pr)
	return s:call_provider('delete_branch', [a:pr])
endfu

fu! critiq#pr#repo_url(issue)
	return s:call_provider('repo_url', [a:issue])
endfu
