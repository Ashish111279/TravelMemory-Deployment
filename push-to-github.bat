@echo off
REM Travel Memory Deployment - GitHub Push Script
REM Run this after creating the GitHub repository

echo ====================================
echo Travel Memory - GitHub Push Script
echo ====================================
echo.
echo IMPORTANT: Make sure you've created the repository on GitHub first!
echo Visit: https://github.com/new
echo.
echo Repository Name: TravelMemory-Deployment
echo Make it PUBLIC for submission
echo.
pause

cd "C:\Users\Pramod Singh\TravelMemory-Deployment"

echo.
echo ====================================
echo Pushing to GitHub...
echo ====================================
echo.

git push -u origin master

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ====================================
    echo ✅ SUCCESS! Repository pushed to GitHub
    echo ====================================
    echo.
    echo Your repository link is:
    echo https://github.com/Ashish111279/TravelMemory-Deployment
    echo.
    echo Ready to submit to Vlearn!
    echo.
) else (
    echo.
    echo ❌ Error pushing to GitHub
    echo Possible causes:
    echo - Repository not created on GitHub yet
    echo - GitHub credentials not configured
    echo - Network connection issue
    echo.
    echo Try these steps:
    echo 1. Go to https://github.com/new
    echo 2. Create repository: TravelMemory-Deployment (PUBLIC)
    echo 3. Run this script again
    echo.
)

pause
