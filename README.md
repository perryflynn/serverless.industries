# serverless.industries

[![pipeline](https://git.brickburg.de/serverless.industries/blog/badges/master/pipeline.svg)](https://git.brickburg.de/serverless.industries/blog)

[serverless.industries](https://serverless.industries) is a jekyll and gitlab-ci driven
blog for topics like software enginerring, linux, containers, continious integration
and networking.

New articles are created via pull requests.

This blog is open for new authors. 

Feel free to contact the creator and ask for access.

## License

All blog posts are licensed under the [Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/) license.

The source code is licensed unter the [MIT License](https://en.wikipedia.org/wiki/MIT_License).

## Technical Workflow

- Create a new branch
- Write a blog post or page
- Commit & Push
- Wait for staging pipeline
- Rewiew your changes via Staging environment
    - Stage is password protected
    - You can find the URL and the credencials in the job log
- Merge request approval
    - Staging environment gets removed
- New version of the blog page gets deployed
- Profit

## Other Technical Details

- Static page generation with Jekyll and Sass
- Build runs in a custom docker container
- Uses Bootstrap 4 and JQuery for the theme
- Uses Font Awesome

## Run website on local machine

- Install ruby
- Clone repository and open a terminal in the repo folder
- `gem install jekyll bundler`
- `bundle install`
- `chmod a+x start-server.sh`
- `./start-server.sh`
- Open the website in browser
