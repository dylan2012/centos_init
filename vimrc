set number
set ruler
set autowrite
set cursorline
set list
set lcs=tab:\|\ ,nbsp:%,trail:-
highlight LeaderTab guifg=#666666
match LeaderTab /^\t/
highlight Comment ctermfg=green guifg=green
hi CursorLine   cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white
hi CursorColumn cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white
nmap <leader>w :w!<cr>
nmap <leader>f :find<cr>
map <C-A> ggVGY
map! <C-A> <Esc>ggVGY
map <F12> gg=G
vmap <C-c> "+y
nnoremap <F2> :g/^\s*$/d<CR>
nnoremap <C-F2> :vert diffsplit
map <M-F2> :tabnew<CR>
map <F3> :tabnew .<CR>
map <C-F3> \be
set tabstop=4
set shortmess=atI
map <F3> :tabnew .<CR>
set statusline=\ %<%F[%1*%M%*%n%R%H]%=\ %y\ %0(%{&fileformat}\ %{&encoding}\ %c:%l/%L%)\[%p%%]
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [POS=%l,%v][%p%%]\ %{strftime(\"%y-%m-%d\ -\ %H:%M:%S\")}
set laststatus=2
