# The DocPad Configuration File
# It is simply a CoffeeScript Object which is parsed by CSON
docpadConfig = {

	# =================================
	# Template Data
	# These are variables that will be accessible via our templates
	# To access one of these within our templates, refer to the FAQ: https://github.com/bevry/docpad/wiki/FAQ

	templateData:

		# Specify some site properties
		site:
			# The production url of our website
			url: "http://softwareninjaneer.com"

			# Here are some old site urls that you would like to redirect from
			oldUrls: [
			]

			# The default title of our website
			title: "Ahmad Mageed - Software Ninjaneer"

			# The website description (for SEO)
			description: """
				Ahmad Mageed on software engineering, .NET, C#, JavaScript, Regex and technology in general.
				"""

			# The website keywords (for SEO) separated by commas
			keywords: """
				software, engineering, development, regex, C#, JavaScript, AngularJS
				"""

			# The website author's name
			author: "Ahmad Mageed"

			# The website author's email
			email: "your@email.com"

			# Styles
			styles: [
				"/vendor/twitter-bootstrap/dist/css/bootstrap.min.css"
				"/styles/style.css"
			]

			# Scripts
			scripts: [
				"/scripts/jquery.js"
				#"//ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"
				"//cdnjs.cloudflare.com/ajax/libs/modernizr/2.6.2/modernizr.min.js"
				"/vendor/twitter-bootstrap/dist/js/bootstrap.min.js"
				# "/scripts/scripts.js"
			]

			# Docpad Services
			services:
				buttons: ['HackerNewsSubmit', 'RedditSubmit', 'GooglePlusOne', 'TwitterTweet', 'TwitterFollow']
				twitterTweetButton: 'amageed'
				twitterFollowButton: 'amageed'
				disqus: 'softwareninjaneer'
				googleAnalytics: 'UA-25934924-1'

		# -----------------------------
		# Helper Functions

		# Get the prepared site/document title
		# Often we would like to specify particular formatting to our page's title
		# we can apply that formatting here
		getPreparedTitle: ->
			# if we have a document title, then we should use that and suffix the site's title onto it
			if @document.title
				"#{@document.title} | #{@site.title}"
			# if our document does not have it's own title, then we should just use the site's title
			else
				@site.title

		# Get the prepared site/document description
		getPreparedDescription: ->
			# if we have a document description, then we should use that, otherwise use the site's description
			@document.description or @site.description

		# Get the prepared site/document keywords
		getPreparedKeywords: ->
			# Merge the document keywords with the site keywords
			@site.keywords.concat(@document.keywords or []).join(', ')

	# =================================
	# Collections
	# These are special collections that our website makes available to us

	collections:
		pages: (database) ->
			database.findAllLive({pageOrder: $exists: true}, [pageOrder:1,title:1])

		posts: (database) ->
			database.findAllLive({relativeOutDirPath:'blog'}, [date:-1])
			# database.findAllLive({tags:$has:'post'}, [date:-1])


	# =================================
	# Plugins

	# Note: highlightjs had to be directly updated to change config.className to 'hljs'
	plugins:
		downloader:
			downloads: [
				{
					name: 'Twitter Bootstrap'
					path: 'src/files/vendor/twitter-bootstrap'
					url: 'https://codeload.github.com/twbs/bootstrap/tar.gz/master'
					tarExtractClean: true
				}
			]
		ghpages:
			deployRemote: 'target'
			deployBranch: 'master'

	# =================================
	# DocPad Events

	# Here we can define handlers for events that DocPad fires
	# You can find a full listing of events on the DocPad Wiki
	events:

		# Render Document
		# https://github.com/bevry/docpad/issues/402
		renderDocument: (opts) ->
			return if 'development' in @docpad.getEnvironments()
			if opts.extension is 'html'
				siteUrl = @docpad.getConfig().templateData.site.url.replace(/\/+$/, '')
				opts.content = opts.content.replace(/(['"])\/([^\/])/g, "$1#{siteUrl}/$2")

		# Server Extend
		# Used to add our own custom routes to the server before the docpad routes are added
		serverExtend: (opts) ->
			# Extract the server from the options
			{server} = opts
			docpad = @docpad

			# As we are now running in an event,
			# ensure we are using the latest copy of the docpad configuraiton
			# and fetch our urls from it
			latestConfig = docpad.getConfig()
			oldUrls = latestConfig.templateData.site.oldUrls or []
			newUrl = latestConfig.templateData.site.url

			# Redirect any requests accessing one of our sites oldUrls to the new site url
			server.use (req,res,next) ->
				if req.headers.host in oldUrls
					res.redirect(newUrl+req.url, 301)
				else
					next()
}


# Export our DocPad Configuration
module.exports = docpadConfig
