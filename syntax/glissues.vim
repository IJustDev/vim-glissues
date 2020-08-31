" Vim syntax file
" Language: Kreisbote
" Maintainer: Alexander Panov
" Latest Revision: 2020

if exists("b:current_syntax")
  finish
endif

syn match glissues /Title/
syn match glissues /\cDescription:/
syn match glissues /\cConfidential:/
syn match glissues /\cLabels:/
syn match glissues /\cDue Date (YYYY-MM-DD):/

hi glissues ctermfg=red
