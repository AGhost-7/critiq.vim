
" Diff parser used to figure out where to place the comments based on the
" location of the cursor.

let s:file_pattern = 'diff\s\+--git\s\+a/\(.\+\)\s\+b/\(.\+\)'
let s:offset_pattern = '^@@ -\(\d\+\),\(\d\+\) +\(\d\+\),\(\d\+\) @@'

fu! s:skip_metadata(iterator, diff_map)
	while a:iterator.index < a:iterator.end
		let line = a:iterator.data[a:iterator.index]
		let a:iterator.index += 1
		call add(a:diff_map, 0)
		if match(line, '+++') == 0
			break
		endif
	endwhile
endfu

fu! s:parse_diff_contents(iterator, current_file, diff_map) abort
	let chunk_offset = [0, 0, 0, 0]
	let add_position = 0
	let rm_position = 0
	let file_index = 0

	while a:iterator.index < a:iterator.end
		let line = a:iterator.data[a:iterator.index]
		if match(line, 'diff') == 0
			break
		endif
		let a:iterator.index += 1
		if match(line, '+') == 0
			call add(a:diff_map, {
				\ 'file': a:current_file,
				\ 'offset': chunk_offset,
				\ 'position': add_position,
				\ 'file_index': file_index,
				\ })
			let add_position += 1
			let file_index += 1
		elseif match(line, '-') == 0
			call add(a:diff_map, {
				\ 'file': a:current_file,
				\ 'offset': chunk_offset,
				\ 'position': rm_position,
				\ 'file_index': file_index,
				\ })
			let rm_position += 1
			let file_index += 1
		elseif match(line, ' ') == 0
			" This isn't a line that was modified, just extra lines provided by the 
			" diff to get a better visual of what was changed.
			call add(a:diff_map, {
				\ 'file': a:current_file,
				\ 'offset': chunk_offset,
				\ 'position': add_position,
				\ 'file_index': file_index,
				\ })
			let add_position += 1
			let rm_position += 1
			let file_index += 1
		elseif match(line, '\') == 0 || line == ''
			" Apparently unified diffs have comments ^^
			" These do not count towards the file index.
			call add(a:diff_map, 0)
		elseif match(line, '@@\s\+-0,0\s\++1\s\+@@') == 0
			let rm_position = 0
			let add_position = 1
			call add(a:diff_map, 0)
			let file_index += 1
		else
			let offset_match = matchlist(line, s:offset_pattern)
			if !empty(offset_match)
				let chunk_offset = map(offset_match[1:4], 'str2nr(v:val)')
				let rm_position = chunk_offset[0]
				let add_position = chunk_offset[2]
				call add(a:diff_map, 0)
				let file_index += 1
			else
				throw 'Could not parse diff at index ' . a:iterator['index'] . ' line "' . line . '"'
			endif
		endif
	endwhile
endfu

fu! critiq#diff#parse(diff_lines) abort

	let iterator = {
		\ 'index': 0,
		\ 'end': len(a:diff_lines),
		\ 'data': a:diff_lines
		\ }

	let diff_map = []
	let current_file = ''

	while iterator.index < iterator.end - 1
		let line = iterator.data[iterator.index]
		let iterator.index += 1
		let file_match = matchlist(line, s:file_pattern)
		if !empty(file_match)
			let current_file = file_match[1]
			call add(diff_map, 0)
			call s:skip_metadata(iterator, diff_map)
			call s:parse_diff_contents(iterator, current_file, diff_map)
		endif
	endwhile
	return diff_map
endfu

