<h2>Current Storage Options</h2>
<p>
	<cfdirectory action="list" directory="#ExpandPath('/')#/plugins/cacheonwheels/cache/storage" name="storageOptions" filter="*.cfc" sort="name">
	<cfdirectory action="list" directory="#ExpandPath('/')#/storage" name="udStorageOptions">
	
	<cfquery name="storageOptions" dbtype="query" >
		SELECT
			*
		FROM
			storageOptions
		UNION
		SELECT
			*
		FROM
			udStorageOptions
	</cfquery>
	
	<cfset activeStorage = application.cacheonwheels.storage />
	
	<ul>
		<cfoutput query="storageOptions">
			
			<cfif NOT ListFindNoCase("BaseStorage.cfc,AbstractStorage.cfc", storageOptions.name)>
				<li>#ListFirst(storageOptions.name, ".")# #LCase(activeStorage) eq LCase(ListFirst(storageOptions.name, ".")) ? '<b class="baseWheelsColor">(Active)</b>' : ''#</li>
			</cfif>
		</cfoutput>
	</ul>
</p>