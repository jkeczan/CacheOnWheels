<cfinterface>
	
	<cffunction name="add" access="public" returntype="void" >
		<cfargument name="key" required="true" type="string" /> 
		<cfargument name="value" required="true" type="any" /> 
		<cfargument name="time" type="numeric" required="false" />
		<cfargument name="category" type="string" required="false"  />
		<cfargument name="currentTime" type="date" required="false" />
	</cffunction>
	
	<cffunction name="get" access="public" returntype="any">
		<cfargument name="key" required="true" type="string" /> 
		<cfargument name="category" type="string" required="false">
		<cfargument name="currentTime" type="date" required="false">
	</cffunction>
	
	<cffunction name="isAvailable" access="public" returntype="boolean" >
		
	</cffunction>
	
	<cffunction name="delete" access="public" returntype="void" >
		<cfargument name="key" required="true" type="string" /> 
		<cfargument name="category" required="false" type="string">
	</cffunction>
	
	<cffunction name="clear" access="public" returntype="void" >
		<cfargument name="category" required="false" type="string"  /> 
	</cffunction>
	
	<cffunction name="getStats" access="public" returntype="Any" >
		
	</cffunction>
</cfinterface>