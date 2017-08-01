nnoremap <buffer> q :tabc<cr>
nnoremap <buffer> o :call critiq#open_pr()<cr>
nnoremap <buffer> <cr> :call critiq#open_pr()<cr>
nnoremap <buffer> b :call critiq#browse_from_pr_list()<cr>
nnoremap <buffer> <leader>i :call critiq#jira#cursor_browse_issue()<cr>
