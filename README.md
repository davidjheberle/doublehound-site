# doublehound.com

The Double Hound website, served by GitHub Pages at https://doublehound.com. It holds a privacy policy for each game.

## Adding a game's privacy policy

1. Make a folder named after the game, for example `my-game/`.
2. Add `my-game/privacy.md` starting with this header, then paste the policy in Markdown below it:

   ```
   ---
   layout: policy
   title: My Game Privacy Policy
   description: Privacy policy for My Game by Double Hound.
   game: My Game
   permalink: /my-game/privacy/
   ---
   ```

3. Commit to `main`. GitHub Pages rebuilds in a minute or two, the policy appears at `https://doublehound.com/my-game/privacy/`, and the home page lists it automatically.

Every `## Heading` gets a link anchor made from its text, so `## Deleting your account` can be linked as `#deleting-your-account` (Google Play's account deletion URL uses this).

## Editing a policy

Edit the game's `privacy.md`, update its effective date, and commit.

## Files

- `shared/` holds everything the pages share: the page templates (`shared/_layouts/`), the style (`shared/site.css`), the logo and the icons.
- `CNAME` tells GitHub Pages to serve the site at doublehound.com. Don't delete it.

## Preview locally (optional)

```
gem install jekyll kramdown-parser-gfm
jekyll serve
```

Then open http://localhost:4000.

The settings files (`_config.yml`, `CNAME`, `404.html`, `.gitignore`) have to stay at the top of the repo, because GitHub Pages and git only look for them there.

## Checking the site

Run `bash check-site.sh` to test DNS, the HTTPS certificate, every page and redirect, and the doublehoundgames.com redirect. If the GitHub CLI (`gh`) is installed and signed in, it also shows the Pages settings and GitHub's own domain health check.
