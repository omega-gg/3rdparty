cd "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build"

call vcvarsall.bat x86 && "C:\Program Files\Git\bin\bash.exe" -c "printenv PATH"
call vcvarsall.bat x64 && "C:\Program Files\Git\bin\bash.exe" -c "printenv PATH"
