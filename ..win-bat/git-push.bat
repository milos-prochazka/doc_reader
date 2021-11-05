cd ..
if .%1.==.. goto syntax

dart-format .\ 2
dart-prep --enable-all .\
del *.bak /q /s

git add --all
git commit --all -m %1
git push origin master --force
pause

git gc
git gc --aggressive
git prune

goto end

:syntax
@echo Syntax: git-push "message"
:end
