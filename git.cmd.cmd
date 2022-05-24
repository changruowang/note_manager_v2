start /b git pull
cd hexo_bolg_files
call hexo clean
cd ..
git add .
git commit -m "Sync"
git push