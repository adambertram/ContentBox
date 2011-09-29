﻿/**
* The main BlogBox engine handler
*/
component singleton{

	// DI
	property name="categoryService"		inject="id:categoryService@bb";
	property name="entryService"		inject="id:entryService@bb";
	property name="pageService"			inject="id:pageService@bb";
	property name="authorService"		inject="id:authorService@bb";
	property name="commentService"		inject="id:commentService@bb";
	property name="bbHelper"			inject="id:bbhelper@bb";
	property name="rssService"			inject="rssService@bb";

	// pre Handler
	function preHandler(event,action,eventArguments){
		// Determine used layout
		var rc 	= event.getCollection();
		var prc = event.getCollection(private=true);
		
		// set blog layout
		event.setLayout("#prc.bbLayout#/layouts/blog");
		// Get all categories
		prc.categories = categoryService.list(sortOrder="category desc",asQuery=false);
		
		// Home page determination
		if( event.getCurrentRoute() eq "/" AND prc.bbSettings.bb_site_homepage neq "bbBlog"){
			event.overrideEvent("blogbox-ui:blog.page");
			rc.pageSlug = prc.bbSettings.bb_site_homepage;
		}
	}
	
	/**
	* The preview page
	*/
	function preview(event,rc,prc){
		event.paramValue("h","");
		event.paramValue("l","");
		
		var author = getModel("securityService@bb").getAuthorSession();
		// valid Author?
		if( author.isLoaded() AND author.isLoggedIn() AND compareNoCase( hash(author.getAuthorID()), rc.h) EQ 0){
			// Override layouts
			event.setLayout("#rc.l#/layouts/blog").overrideEvent("blogbox-ui:blog.index");
			// Place layout on scope
			prc.bbLayout = rc.l;
			// Place layout root location
			prc.bbLayoutRoot = prc.bbRoot & "/layouts/" & rc.l;
			// preview it
			index(argumentCollection=arguments);
		}
		else{
			setNextEvent(URL=bbHelper.linkHome());
		}
	}

	/**
	* The home page
	*/
	function index(event,rc,prc){
		// incoming params
		event.paramValue("page",1);
		event.paramValue("category","");
		event.paramValue("q","");
		
		// prepare paging plugin
		prc.pagingPlugin 		= getMyPlugin(plugin="Paging",module="blogbox");
		prc.pagingBoundaries	= prc.pagingPlugin.getBoundaries();
		prc.pagingLink 			= bbHelper.linkHome() & "?page=@page@";
		
		// Search Paging Link Override?
		if( len(rc.q) ){
			prc.pagingLink = bbHelper.linkHome() & "/search/#rc.q#/@page@?";
		}
		// Category Filter Link Override
		if( len(rc.category) ){
			prc.pagingLink = bbHelper.linkHome() & "/category/#rc.category#/@page@?";
		}
		
		// get published entries
		var entryResults = entryService.findPublishedEntries(offset=prc.pagingBoundaries.startRow-1,
											   				 max=prc.bbSettings.bb_paging_maxentries,
											   				 category=rc.category,
											   				 searchTerm=rc.q);
		prc.entries 		= entryResults.entries;
		prc.entriesCount  	= entryResults.count;
		
		// announce event
		announceInterception("bbui_onIndex",{entries=prc.entries,entriesCount=prc.entriesCount});
		
		// set skin view
		event.setView("#prc.bbLayout#/views/index");
	}
	
	/**
	* The archives
	*/
	function archives(event,rc,prc){
		// incoming params
		event.paramValue("page",1);
		// archived params
		event.paramValue("year","0");
		event.paramValue("month","0");
		event.paramValue("day","0");
		
		// prepare paging plugin
		prc.pagingPlugin 		= getMyPlugin(plugin="Paging",module="blogbox");
		prc.pagingBoundaries	= prc.pagingPlugin.getBoundaries();
		prc.pagingLink 			= bbHelper.linkHome() & event.getCurrentRoutedURL() & "?page=@page@";
		
		// get published entries
		var entryResults = entryService.findPublishedEntriesByDate(year=rc.year,
											   				  	   month=rc.month,
											   				 	   day=rc.day,
											   				 	   offset=prc.pagingBoundaries.startRow-1,
											   					   max=prc.bbSettings.bb_paging_maxentries);
		prc.entries 		= entryResults.entries;
		prc.entriesCount  	= entryResults.count;
		
		// announce event
		announceInterception("bbui_onArchives",{entries=prc.entries,entriesCount=prc.entriesCount});
		
		// set skin view
		event.setView("#prc.bbLayout#/views/archives");
	}
	
	/**
	* An entry page
	*/
	function entry(event,rc,prc){
		// incoming params
		event.paramValue("entrySlug","");
		
		// Try to retrieve by slug
		prc.entry = entryService.findBySlug(rc.entrySlug);
		
		// Check if loaded, else not found
		if( prc.entry.isLoaded() ){
			// Record hit
			entryService.updateHits( prc.entry );
			// Retrieve Comments
			// TODO: paging
			var commentResults 	= commentService.findApprovedComments(entryID=prc.entry.getEntryID());
			prc.comments 		= commentResults.comments;
			prc.commentsCount 	= commentResults.count;
			// announce event
			announceInterception("bbui_onEntry",{entry=prc.entry,entrySlug=rc.entrySlug});
			// set skin view
			event.setView("#prc.bbLayout#/views/entry");	
		}
		else{
			// announce event
			announceInterception("bbui_onPageNotFound",{entry=prc.entry,entrySlug=rc.entrySlug});
			// missing page
			prc.missingPage = rc.entrySlug;
			// set 404 headers
			event.setHTTPHeader("404","Page not found");
			// set skin not found
			event.setView("#prc.bbLayout#/views/notfound");
		}	
	}
	
	/**
	* An normal page
	*/
	function page(event,rc,prc){
		// incoming params
		event.paramValue("pageSlug","");
		
		// Try to retrieve by slug
		prc.page = pageService.findBySlug(rc.pageSlug);
		
		// Check if loaded, else not found
		if( prc.page.isLoaded() ){
			// Record hit
			pageService.updateHits( prc.page );
			// Retrieve Comments
			// TODO: paging
			var commentResults 	= commentService.findApprovedComments(pageID=prc.page.getPageID());
			prc.comments 		= commentResults.comments;
			prc.commentsCount 	= commentResults.count;
			// announce event
			announceInterception("bbui_onPage",{page=prc.page,pageSlug=rc.pageSlug});
			// set skin view
			event.setView(view="#prc.bbLayout#/views/page",layout="#prc.bbLayout#/layouts/#prc.page.getLayout()#");	
		}
		else{
			// announce event
			announceInterception("bbui_onPageNotFound",{page=prc.page,pageSlug=rc.pageSlug});
			// missing page
			prc.missingPage = rc.pageSlug;
			// set 404 headers
			event.setHTTPHeader("404","Page not found");
			// set skin not found
			event.setView(view="#prc.bbLayout#/views/notfound",layout="#prc.bbLayout#/layouts/pages");
		}	
	}
	
	/*
	* Error Pages
	*/
	function onError(event,faultAction,exception,eventArguments){
		// Determine used layout
		var rc 	= event.getCollection();
		var prc = event.getCollection(private=true);
		
		// store exceptions
		prc.faultAction = arguments.faultAction;
		prc.exception   = arguments.exception;
		
		// announce event
		announceInterception("bbui_onError",{faultAction=arguments.faultAction,exception=arguments.exception,eventArguments=arguments.eventArguments});
			
		// Set view to render
		event.setView("#prc.bbLayout#/views/error");
	}

	/**
	* Comment Form Post
	*/
	function commentPost(event,rc,prc){
		// param values
		event.paramValue("contentID","");
		event.paramValue("contentType","blog");
		event.paramValue("author","");
		event.paramValue("authorURL","");
		event.paramValue("authorEmail","");
		event.paramValue("content","");
		event.paramValue("captchacode","");
		
		// check if entry id is empty
		if( !len(rc.contentID) ){
			setNextEvent(prc.bbEntryPoint);
		}
		
		var thisContent = "";
		// entry or page
		switch(rc.contenttype){
			case "page" : {
				thisContent = pageService.get( rc.contentID ); break;
			}
			default: {
				thisContent = entryService.get( rc.contentID ); break;
			}
		}
		// If null, kick them out
		if( isNull(thisContent) ){ setNextEvent(prc.bbEntryPoint); }
		// Check if comments enabled? else kick them out, who knows how they got here
		if( NOT bbHelper.isCommentsEnabled( thisContent ) ){
			getPlugin("MessageBox").warn("Comments are disabled!");
			setNextEvent(bbHelper.linkContent( thisContent ));
		}
		
		// Trim values & XSS Cleanup of fields
		var antiSamy 	= getPlugin("AntiSamy");
		rc.author 		= antiSamy.htmlSanitizer( trim(rc.author) );
		rc.authorEmail 	= antiSamy.htmlSanitizer( trim(rc.authorEmail) );
		rc.authorURL 	= antiSamy.htmlSanitizer( trim(rc.authorURL) );
		rc.captchacode 	= antiSamy.htmlSanitizer( trim(rc.captchacode) );
		rc.content 		= antiSamy.htmlSanitizer( xmlFormat(trim(rc.content)) );
		
		// Validate incoming data
		prc.commentErrors = [];
		if( !len(rc.author) ){ arrayAppend(prc.commentErrors,"Your name is missing!"); }
		if( !len(rc.authorEmail) OR NOT getPlugin("Validator").checkEmail(rc.authorEmail)){ arrayAppend(prc.commentErrors,"Your email is missing or is invalid!"); }
		if( len(rc.authorURL) AND getPlugin("Validator").checkURL(rc.authorURL) ){ arrayAppend(prc.commentErrors,"Your URL is invalid!"); }
		if( !len(rc.content) ){ arrayAppend(prc.commentErrors,"Your URL is invalid!"); }
		
		// Captcha Validation
		if( prc.bbSettings.bb_comments_captcha AND NOT getMyPlugin(plugin="Captcha",module="blogbox").validate( rc.captchacode ) ){
			ArrayAppend(prc.commentErrors, "Invalid security code. Please try again.");
		}
		
		// announce event
		announceInterception("bbui_preCommentPost",{commentErrors=prc.commentErrors,content=thisContent,contentType=rc.contentType});
		
		// Validate if comment errors exist
		if( arrayLen(prc.commentErrors) ){
			// MessageBox
			getPlugin("MessageBox").warn(messageArray=prc.commentErrors);
			// Execute event again
			if( thisContent.getType() eq "entry" ){
				// put slug in request
				rc.entrySlug = thisContent.getSlug();
				// Execute entry again, need to correct form
				entry(argumentCollection=arguments);
			}
			else{
				// put slug in request
				rc.pageSlug = thisContent.getSlug();
				// Execute entry again, need to correct form
				page(argumentCollection=arguments);
			}
			return;			
		}
		
		// Get new comment to persist
		var comment = populateModel( commentService.new() ).setRelatedContent( thisContent );
		// Data is valid, let's send it to the comment service for persistence, translations, etc
		var results = commentService.saveComment( comment );
		
		// announce event
		announceInterception("bbui_onCommentPost",{comment=comment,content=thisContent,moderationResults=results,contentType=rc.contentType});
		
		// Check if all good
		if( results.moderated ){
			// Message
			getPlugin("MessageBox").warn(messageArray=results.messages);
			flash.put(name="commentErrors",value=results.messages,inflateTOPRC=true);
			// relocate back to comments
			setNextEvent(URL=bbHelper.linkComments(thisContent));	
		}
		else{
			// relocate back to comment
			setNextEvent(URL=bbHelper.linkComment(comment));		
		}		
	}

	/**
	* Display the RSS feeds
	*/
	function rss(event,rc,prc){
		// params
		event.paramValue("category","");
		event.paramValue("entrySlug","");
		event.paramValue("commentRSS",false);
		
		// Build out the RSS feeds
		var feed = RSSService.getRSS(comments=rc.commentRSS,category=rc.category,entrySlug=rc.entrySlug);
		
		// Render out the feed xml
		event.renderData(type="plain",data=feed,contentType="text/xml");
	}

}