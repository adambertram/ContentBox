﻿<cfoutput>
<div id="pagerContent">
<!--- Loader --->
<div class="loaders floatRight" id="contentPagerLoader">
	<i class="fa fa-spinner fa-spin icon-large"></i>
</div>

<!--- content --->
<table name="content_pager" id="content_pager" class="table-bordered table table-hover table-condensed table-striped" width="100%">
	<thead>
		<tr class="info">
			<th>Title</th>
			<th width="40" class="text-center"><i class="fa fa-globe icon-large" title="Published Status"></i></th>
			<th width="50" class="text-center">Actions</th>
		</tr>
	</thead>

	<tbody>
		<cfloop array="#prc.pager_content#" index="content">
		<tr data-contentID="#content.getContentID()#"
			<cfif content.isExpired()>
				class="error"
			<cfelseif content.isPublishedInFuture()>
				class="success"
			<cfelseif !content.isContentPublished()>
				class="warning"
			</cfif>>
			<td>
				<a href="#event.buildLink(prc.xehContentEditor)#/contentID/#content.getContentID()#" title="Edit #content.getTitle()#">#content.getTitle()#</a><br/>
				<small>
				<i class="fa fa-user" title="last edit by"></i> <a href="mailto:#content.getAuthorEmail()#">#content.getAuthorName()#</a> on #content.getActiveContent().getDisplayCreatedDate()#
				</small>
			</td>
			<td class="text-center">
				<cfif content.isExpired()>
					<i class="fa fa-clock-o icon-large textRed" title="Content has expired!"></i>
					<span class="hidden">expired</span>
				<cfelseif content.isPublishedInFuture()>
					<i class="fa fa-fighter-jet icon-large textBlue" title="Content Publishes in the future!"></i>
					<span class="hidden">published in future</span>
				<cfelseif content.isContentPublished()>
					<i class="fa fa-check icon-large textGreen" title="Content Published!"></i>
					<span class="hidden">published in future</span>
				<cfelse>
					<i class="fa fa-check icon-large textRed" title="Content Draft!"></i>
					<span class="hidden">draft</span>
				</cfif>
			</td>
			<td class="text-center">
				<!--- content Actions --->
				<div class="btn-group btn-group-xs">
			    	<a class="btn btn-xs btn-primary dropdown-toggle" data-toggle="dropdown" href="##" title="Content Actions">
						<i class="fa fa-cogs icon-large"></i>
					</a>
			    	<ul class="dropdown-menu text-left pull-right">
			    		<cfif prc.oAuthor.checkPermission("CONTENTSOTE_EDITOR,CONTENTSTORE_ADMIN")>
						<!--- Edit Command --->
						<li><a href="#event.buildLink(prc.xehContentEditor)#/contentID/#content.getContentID()#"><i class="fa fa-edit icon-large"></i> Edit</a></li>
						</cfif>
						<!--- History Command --->
						<li><a href="#event.buildLink(prc.xehContentHistory)#/contentID/#content.getContentID()#"><i class="fa fa-clock-o icon-large"></i> History</a></li>
			    	</ul>
			    </div>
			</td>
		</tr>
		</cfloop>
	</tbody>
</table>

<!--- Paging --->
<cfif prc.pager_pagination>
	#prc.pager_pagingPlugin.renderit(foundRows=prc.pager_contentCount, link=prc.pager_pagingLink, asList=true)#
</cfif>
</div>
</cfoutput>