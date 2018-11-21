
" Contains generic functions to perform various API calls

fu! s:call_provider(function_name, args)
	" TODO: determine provider through tab local variable?
	let provider_name = 'github'
	call critiq#providers#github#request(a:function_name, a:args)
endfu

fu! critiq#pr#list_open_prs(callback, page, ...)
	let args = [a:callback, a:page] + a:000
	call s:call_provider('list_open_prs', args)
endfu

fu! critiq#pr#pull_request(issue, callback)
	call s:call_provider('pull_request', [a:issue, a:callback])
endfu

fu! critiq#pr#diff(issue, callback)
	call s:call_provider('diff', [a:issue, a:callback])
endfu

fu! critiq#pr#submit_review(pr, event, body)
	call s:call_provider('submit_review', [a:pr, a:event, a:body])
endfu

fu! critiq#pr#submit_comment(pr, line, body)
	call s:call_provider('submit_comment', [a:pr, a:line, a:body])
endfu

fu! critiq#pr#merge_pr(pr)
	call s:call_provider('merge_pr', [a:pr])
endfu

fu! critiq#pr#browse_pr(pr)
	call s:call_provider('browse_pr', [a:pr])
endfu

fu! critiq#pr#pr_comments(issue, callback)
	call s:call_provider('pr_comments', [a:issue, a:callback])
endfu

fu! critiq#pr#checkout(pr)
	call s:call_provider('checkout', [a:pr])
endfu

fu! critiq#pr#pull(pr)
	call s:call_provider('pull', [a:pr])
endfu

fu! critiq#pr#repo_labels(issue, callback)
	call s:call_provider('repo_labels', [a:issue, a:callback])
endfu

fu! critiq#pr#toggle_label(pr, repo_labels, pr_labels, label_index, callback)
	call s:call_provider('toggle_label', [a:pr, a:repo_labes, a:pr_labels, a:label_index, a:callback])
endfu

fu! critiq#pr#pr_reviews(issue, callback)
	call s:call_provider('pr_reviews', [a:issue, a:callback])
endfu

fu! critiq#pr#repo_url(issue)
	call s:call_provider('repo_url', [a:issue])
endfu
