mkdir "temp" 2> nul
tools\armips src.s -strequ ver "bn6f.s"
if errorlevel 1 pause
tools\armips src.s -strequ ver "bn6g.s"
if errorlevel 1 pause