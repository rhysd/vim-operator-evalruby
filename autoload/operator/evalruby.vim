function! operator#evalruby#do(motion_wise)

    if ! executable(g:operator_evalruby_command)
        echoerr g:operator_evalruby_command.' is not found!'
        return
    endif

    let sel_save = &l:selection
    let &l:selection = "inclusive"
    let save_g_reg = getreg('g', 1)
    let save_g_regtype = getregtype('g')

    let put_command = (s:deletion_moves_the_cursor_p(
                    \   a:motion_wise,
                    \   getpos("']")[1:2],
                    \   len(getline("']")),
                    \   [line('$'), len(getline('$'))]
                    \ )
                    \ ? 'p' : 'P')

    try
        let visual_command = s:visual_command_from_wise_name(a:motion_wise)
        if s:is_empty_region(getpos("'["), getpos("']"))
            return
        end
        execute 'normal!' '`['.visual_command.'`]"gy'

        let expr = 'puts lambda{'
                    \ . substitute(getreg('g'), '"', '\\"', 'g')
                    \ . '}.call'
        let result = s:system(g:operator_evalruby_command . ' -e "' . expr . '"')
        let error = s:has_vimproc() ? vimproc#get_last_status() : v:shell_error

        if error
            echoerr "evalruby: error!!\n".result
        else
            call setreg('g', result, 'v')
            " normal! gv"gp
            execute 'normal!' 'gv"g'.put_command
        endif
    finally
        call setreg('g', save_g_reg, save_g_regtype)
        let &l:selection = sel_save
    endtry

endfunction


function! s:deletion_moves_the_cursor_p( motion_wise,
                                       \ motion_end_pos,
                                       \ motion_end_last_col,
                                       \ buffer_end_pos )
  let [buffer_end_line, buffer_end_col] = a:buffer_end_pos
  let [motion_end_line, motion_end_col] = a:motion_end_pos

  if a:motion_wise ==# 'char'
    return ( (a:motion_end_last_col == motion_end_col)
           \ || (buffer_end_line == motion_end_line
           \     && buffer_end_col <= motion_end_col) )
  elseif a:motion_wise ==# 'line'
    return buffer_end_line == motion_end_line
  elseif a:motion_wise ==# 'block'
    return 0
  else
    echoerr 'Invalid wise name:' string(a:wise_name)
    return 0
  endif
endfunction


function! s:is_empty_region(begin, end)
    " Whenever 'operatorfunc' is called, '[ is always placed before '] even if
    " a backward motion is given to g@.  But there is the only one exception.
    " If an empty region is given to g@, '[ and '] are set to the same line, but
    " '[ is placed after '].
    return a:begin[1] == a:end[1] && a:end[2] < a:begin[2]
endfunction


function! s:visual_command_from_wise_name(wise_name)
    if a:wise_name ==# 'char'
        return 'v'
    elseif a:wise_name ==# 'line'
        return 'V'
    elseif a:wise_name ==# 'block'
        return "\<C-v>"
    else
        echoerr 'E1: Invalid wise name:' string(a:wise_name)
        return 'v'  " fallback
    endif
endfunction

function! s:has_vimproc()
  if !exists('s:exists_vimproc')
    try
      call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif
  return s:exists_vimproc
endfunction

function! s:system(...)
    let cmd = join(a:000, ' ')
    if s:has_vimproc()
        return vimproc#system(cmd)
    else
        return system(cmd)
    endif
endfunction
