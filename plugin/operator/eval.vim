if exists('g:loaded_operator_eval')
  finish
endif
let g:loaded_operator_eval = 1

let g:operator_eval_ruby_command = get(g:, 'operator_eval_ruby_command', 'ruby')

call operator#user#define('eval', 'operator#eval#do')
