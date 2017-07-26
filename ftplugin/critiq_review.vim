nnoremap <buffer> q :bd<cr>
nnoremap <buffer> s :call critiq#send_review(b:critiq_state)<cr>
nnoremap <buffer> b :call critiq#github#browse_pr(b:critiq_pull_request)<cr>
