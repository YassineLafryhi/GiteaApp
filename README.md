# Gitea.app
### The easiest way to get started with Gitea on the Mac

*Just download, drag to the applications folder, and double-click.*

![Screenshot](Screenshot.png)

### [Download](https://github.com/YassineLafryhi/GiteaApp/releases/download/1.0.0/Gitea.zip)

--

### How to build

```bash
git clone https://github.com/YassineLafryhi/GiteaApp.git
cd GiteaApp
mkdir App && cd App
wget https://github.com/go-gitea/gitea/releases/download/v1.21.5/gitea-1.21.5-darwin-10.12-arm64
wget https://github.com/go-gitea/gitea/releases/download/v1.21.5/gitea-1.21.5-darwin-10.12-amd64
mv gitea-1.21.5-darwin-10.12-arm64 gitea-arm64
mv gitea-1.21.5-darwin-10.12-amd64 gitea-amd64
chmod +x gitea-arm64 && chmod +x gitea-amd64
cd ..
xcodebuild
open build/Release
# then move Gitea.app to /Applications folder
```

### Credits

Forked and adapted from [Redis.app](https://github.com/jpadilla/redisapp).
