
fu! critiq#views#pr_file#render()
	let line_diff = t:critiq_pr_diff[line('.') - 1]
	if !empty(line_diff)
		exe 'botright vsplit ' line_diff.file

		exe ':' line_diff.position

		call critiq#pr_tab_commands()

		if !exists("g:critiq_no_mappings")
			nnoremap <buffer> q :bd<cr>
			call critiq#pr_tab_mappings()
		endif

		call critiq#trigger_event("CritiqOpenFile")

	endif
endfu
