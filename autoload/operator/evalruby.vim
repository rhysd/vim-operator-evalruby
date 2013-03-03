function! operator#evalruby#do(motion_wise)

    if ! executable(g:operator_evalruby_command)
        echoerr g:operator_evalruby_command.' is not found!'
        return
    endif

    let save_g_reg = getreg('g')

    let put_command = (s:deletion_moves_the_cursor_p(
                    \   a:motion_wise,
                    \   getpos("']")[1:2],
                    \   len(getline("']")),
                    \   [line('$'), len(getline('$'))]
                    \ )
                    \ ? 'p'
                    \ : 'P')

    try
        " get region to register g
        let visual_command = s:visual_command_from_wise_name(a:motion_wise)
        if s:is_empty_region(getpos("'["), getpos("']"))
            return
        end
        execute 'normal!' '`['.visual_command.'`]"gd'

        let expr = 'puts lambda{'.getreg('g').'}.call'
        let result = system(g:operator_evalruby_command . ' -e ''' . expr.'''')

        if v:shell_error
            " restore and print error
            execute 'normal!' '"g'.put_command
            echoerr "evalruby: error!!\n".result
        else
            " success
            call setreg('g', result)
            execute 'normal!' '"g'.put_command
        endif

    finally
        call setreg('g', save_g_reg)
    endtry

endfunction


function! s:deletion_moves_the_cursor_p(motion_wise,
\                                       motion_end_pos,
\                                       motion_end_last_col,
\                                       buffer_end_pos)
  let [buffer_end_line, buffer_end_col] = a:buffer_end_pos
  let [motion_end_line, motion_end_col] = a:motion_end_pos

  if a:motion_wise ==# 'char'
    return ((a:motion_end_last_col == motion_end_col)
    \       || (buffer_end_line == motion_end_line
    \           && buffer_end_col <= motion_end_col))
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
