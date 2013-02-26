function! operator#eval#do(motion_wise)  "{{{2

    let save_g_reg = getreg('g')

    " get region to register g
    let visual_command = s:visual_command_from_wise_name(a:motion_wise)
    if !s:is_empty_region(getpos("'["), getpos("']"))
        execute 'normal!' '`['.visual_command.'`]"gd'
    end

    let expr = 'puts lambda{'.getreg('g').'}.call'
    let result = system(g:operator_eval_ruby_command . ' -e ''' . expr.'''')
    " XXX
    call setline('.', result)

    call setreg('g', save_g_reg)

    return
endfunction


function! s:is_empty_region(begin, end)  "{{{2
    " Whenever 'operatorfunc' is called, '[ is always placed before '] even if
    " a backward motion is given to g@.  But there is the only one exception.
    " If an empty region is given to g@, '[ and '] are set to the same line, but
    " '[ is placed after '].
    return a:begin[1] == a:end[1] && a:end[2] < a:begin[2]
endfunction


function! s:visual_command_from_wise_name(wise_name)  "{{{2()
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
