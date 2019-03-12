let s:plugin_dir = expand('<sfile>:p:h:h')

let s:U = {}

"
" common
"

" autoload_by_funcname
function! s:U.autoload_by_funcname(fname)
  if !exists('*' . a:fname)
    let file = a:fname
    let file = substitute(file, '#', '/', 'g')
    let file = substitute(file, '/[^/]*$', '.vim', 'g')
    let file = printf('%s/%s', s:plugin_dir, file)
    if filereadable(file)
      execute printf('source %s', file)
    endif
  endif
endfunction

" run_in_dir
function! s:U.run_in_dir(dir, fn)
  let cwd = getcwd()
  try
    execute printf('lcd %s', a:dir)
    let output = a:fn()
  finally
    execute printf('lcd %s', cwd)
  endtry
  return output
endfunction

function! s:U.relative(path, ...)
  return s:U.run_in_dir(get(a:000, 0, getcwd()), { -> fnamemodify(a:path, ':.')})
endfunction

" choose yes/no
function! s:U.yes_or_no(msg)
  let choose = input(a:msg . '(yes/no): ')
  echomsg ' '
  if index(['y', 'ye', 'yes'], choose) > -1
    return v:true
  endif
  return v:false
endfunction

" echomsgs
function! s:U.echomsgs(msgs)
  for msg in s:U.to_list(a:msgs)
    echomsg msg
  endfor
  call input('')
endfunction

" exec
function! s:U.exec(cmd, ...)
  return execute(call('printf', [a:cmd] + a:000))
endfunction

" escape
function! s:U.shellargs(args)
  let args = []
  for arg in s:U.to_list(a:args)
    if type(arg) == v:t_list
      let args = args + [join(map(arg, { k, v -> escape(v, ' ') }), ' ')]
      continue
    endif
    if type(arg) == v:t_dict
      let args = args + [s:U.opts(arg)]
      continue
    endif
    call add(args, arg)
  endfor
  return args
endfunction

" combine
function! s:U.combine(columns, values)
  let i = 0
  let dict = {}
  for [key, Converter] in a:columns
    let dict[key] = Converter(a:values[i])
    let i = i + 1
  endfor
  return dict
endfunction

" opts
function! s:U.opts(opts)
  let args = []
  for [k, v] in items(a:opts)
    if type(v) == v:t_bool && s:v
      call add(args, k)
    else
      call add(args, k . '=' . v)
    endif
  endfor
  return join(args, ' ')
endfunction

" to_list
function! s:U.to_list(v)
  if type(a:v) == v:t_list
    return a:v
  endif
  return [a:v]
endfunction

" or
function! s:U.or(v1, v2)
  return strlen(a:v1) ? a:v1 : a:v2
endfunction

" chomp
function! s:U.chomp(s)
  return substitute(a:s, '\(\r\n\|\r\|\n\)*$', '', 'g')
endfunction

"
" status
"
let s:U.status = {}

" status.parse
function! s:U.status.parse(line)
  let status = strpart(a:line, 0, 2)
  let path = strpart(a:line, 3)
  return {
        \ 'status': status,
        \ 'path': fnamemodify(s:U.status.parse_path(status, path), ':p'),
        \ 'raw': a:line
        \ }
endfunction

" status.parse_path
function! s:U.status.parse_path(state, path)
  if a:state =~# 'R'
    return split(a:path, ' -> ')[1]
  endif
  return a:path
endfunction

function! gitto#util#get()
  return s:U
endfunction

