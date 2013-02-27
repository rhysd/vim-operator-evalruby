if exists('g:loaded_operator_evalruby')
  finish
endif
let g:loaded_operator_evalruby = 1

let g:operator_evalruby_command = get(g:, 'operator_evalruby_command', 'ruby')

call operator#user#define('evalruby', 'operator#evalruby#do')
