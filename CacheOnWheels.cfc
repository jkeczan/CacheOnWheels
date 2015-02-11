<cfcomponent>
	<cffunction name="init" >
		<cfset this.version = "1.0" />
		
		<!--- Must use private $wheels directory since the main "wheels" struct isn't initialized yet --->
		<cfset application.cacheonwheels.storage = application.$wheels.cacheStorage />
		<cfset application.cacheonwheels.cacheSettings = {} />

		<cfset $initializeInstance() />
		<cfset $initializeSettings() />
		<cfset $initializeStats() />
		<cfset $initializeCache() />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="$initializeCache" access="public" returntype="void" >
		<cfargument name="storage" type="string" required="false" default="#application.cacheonwheels.storage#">
		<cfargument name="cacheSettings" type="struct" required="false" default="#application.cacheonwheels.cacheSettings#">
		<cfargument name="defaultCacheTime" type="numeric" required="false" default="#application.$wheels.defaultCacheTime#">
		<cfargument name="cacheCullPercentage" type="numeric" required="false" default="#application.$wheels.cacheCullPercentage#">
		<cfargument name="cacheCullInterval" type="numeric" required="false" default="#application.$wheels.cacheCullInterval#">
		<cfargument name="maximumItemsToCache" type="numeric" required="false" default="#application.$wheels.maximumItemsToCache#">
		<cfargument name="cacheDatePart" type="string" required="false" default="#application.$wheels.cacheDatePart#">
		<cfargument name="showDebugInformation" type="boolean" required="false" default="#application.$wheels.showDebugInformation#">
		<cfargument name="nameSpaces" type="string" required="false" default="actions,images,pages,partials,schemas">
		<cfargument name="defaultNameSpace" type="string" required="false" default="internal">
		
		<cfset var loc = {} />
		<cfset StructAppend(variables.$instance, arguments) />
		
		<cfset variables.$instance.cacheLastCulledAt = Now() />
		
		<cfif ARGUMENTS.storage eq "">
			<cfset ARGUMENTS.storage = "memory" />
		</cfif>

		<cfset variables.$instance.cache = CreateObject("component", "cache.storage.#ARGUMENTS.storage#").init(argumentCollection=arguments.cacheSettings) />
		
		<cfset $addStatsToCache() />
		
		<cfset application.cacheonwheels = variables.$instance />
	</cffunction>
	
	<cffunction name="$initializeInstance" access="public" returntype="void" >
		<cfset variables.$instance = {} />
	</cffunction>
	
	<cffunction name="$initializeSettings" access="public" returntype="void" >
		<cfset var loc = {} />
		
		<!--- Set defaults for each property necessary for the plugin so no errors occur out of the gate --->
		<cfparam name="application.cacheonwheels.storage" default="#application.cacheonwheels.storage#" />
		<cfparam name="application.cacheonwheels.cacheSettings" default="#StructNew()#" />
	</cffunction>
	
	<cffunction name="$initializeStats" access="public" returntype="void" >
		<cfset var loc = {} />
		
		<cfset loc.stats = {} />
		<cfset loc.hitcount = 0 />
		<cfset variables.$instance.stats = loc.stats />
	</cffunction>
	
	<cffunction name="$addStatsToCache" access="public" returntype="void" >
		<cfset var loc = {} />
		
		<cfset $addToCache("main_stats", variables.$instance.stats, 15) />
	</cffunction>

	<cffunction name="$addToCache" returntype="void" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="value" type="any" required="true">
		<cfargument name="time" type="numeric" required="false" default="#application.wheels.defaultCacheTime#">
		<cfargument name="category" type="string" required="false" default="main">
		
		<cfif $IsAvailable()>
			<cfset application.cacheonwheels.cache.add(argumentCollection=arguments) />
		</cfif>
	</cffunction>
	
	<cffunction name="$getFromCache" returntype="any" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="category" type="string" required="false" default="main">
		<cfreturn application.cacheonwheels.cache.get(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="$removeFromCache" returntype="void" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="category" type="string" required="false" default="main">

		<cfset application.cacheonwheels.cache.delete(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="$clearCache" returntype="void" access="public" output="false">
		<cfargument name="category" type="string" required="false" default="">


		<cfset application.cacheonwheels.cache.clear(ARGUMENTS.category) />
	</cffunction>
	
	<cffunction name="addToCache" returntype="void" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="value" type="any" required="true">
		<cfargument name="time" type="numeric" required="false" default="#application.wheels.defaultCacheTime#">
		<cfargument name="category" type="string" required="false" default="main">
		
		
		<cfset $addToCache(argumentsCollection=ARGUMENTS) />
	</cffunction>
	
	<cffunction name="getFromCache" returntype="any" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="category" type="string" required="false" default="main">
	
		<cfset $getFromCache(argumentsCollection=ARGUMENTS) />
	</cffunction>
	
	<cffunction name="removeFromCache" returntype="void" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="category" type="string" required="false" default="main">

		<cfset $removeToCache(argumentsCollection=ARGUMENTS) />
	</cffunction>
	
	<cffunction name="clearCache" returntype="void" access="public" output="false">
		<cfargument name="category" type="string" required="false" default="">


		<cfset $clearCache(argumentsCollection=ARGUMENTS) />
	</cffunction>
	
	<cffunction name="$isAvailable" access="public" returntype="boolean" >
		<cfreturn StructKeyExists(application.cacheonwheels, "cache") AND IsObject(application.cacheonwheels.cache) />
	</cffunction>
	
	<cffunction name="isAvailable" access="public" returntype="boolean" >
		<cfreturn $isAvailable(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="getCacheStats" access="public" returntype="any" >
		<cfset application.cacheonwheels.cache.getStats() />
	</cffunction>
	
	<cffunction name="findAll" returntype="any" access="public" output="false" mixin="model" hint="Returns records from the database table mapped to this model according to the arguments passed in. (Use the `where` argument to decide which records to get, use the `order` argument to set in what order those records should be returned, and so on). The records will be returned as either a `cfquery` result set or an array of objects (depending on what the `returnAs` argument is set to). Instead of using the `where` argument, you can create cleaner code by making use of a concept called dynamic finders."
	examples=
	'
		<!--- Getting only 5 users and ordering them randomly --->
		<cfset fiveRandomUsers = model("user").findAll(maxRows=5, order="random")>
		<!--- Including an association (which in this case needs to be setup as a `belongsTo` association to `author` on the `article` model first)  --->
		<cfset articles = model("article").findAll(where="published=1", order="createdAt DESC", include="author")>
		<!--- Similar to the above but using the association in the opposite direction (which needs to be setup as a `hasMany` association to `article` on the `author` model) --->
		<cfset bobsArticles = model("author").findAll(where="firstName=''Bob''", include="articles")>
		<!--- Using pagination (getting records 26-50 in this case) and a more complex way to include associations (a song `belongsTo` an album, which in turn `belongsTo` an artist) --->
		<cfset songs = model("song").findAll(include="album(artist)", page=2, perPage=25)>
		<!--- Using a dynamic finder to get all books released a certain year. Same as calling model("book").findOne(where="releaseYear=##params.year##") --->
		<cfset books = model("book").findAllByReleaseYear(params.year)>
		<!--- Getting all books of a certain type from a specific year by using a dynamic finder. Same as calling model("book").findAll(where="releaseYear=##params.year## AND type=''##params.type##''") --->
		<cfset books = model("book").findAllByReleaseYearAndType("##params.year##,##params.type##")>
		<!--- If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `comments` method below will call `model("comment").findAll(where="postId=##post.id##")` internally) --->
		<cfset post = model("post").findByKey(params.postId)>
		<cfset comments = post.comments()>
	'
	categories="model-class,read" chapters="reading-records,associations" functions="findByKey,findOne,hasMany">
	<cfargument name="where" type="string" required="false" default="" hint="This argument maps to the `WHERE` clause of the query. The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR`. (Note that the key words need to be written in upper case.) You can also use parentheses to group statements. You do not need to specify the table name(s); Wheels will do that for you.">
	<cfargument name="order" type="string" required="false" hint="Maps to the `ORDER BY` clause of the query. You do not need to specify the table name(s); Wheels will do that for you.">
	<cfargument name="group" type="string" required="false" hint="Maps to the `GROUP BY` clause of the query. You do not need to specify the table name(s); Wheels will do that for you.">
	<cfargument name="select" type="string" required="false" default="" hint="Determines how the `SELECT` clause for the query used to return data will look.	You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, Wheels will select all properties from your table(s). If you specify a table name (e.g. `users.email`) or alias a column (e.g. `fn AS firstName`) in the list, then the entire list will be passed through unchanged and used in the `SELECT` clause of the query. By default, all column names in tables `JOIN`ed via the `include` argument will be prepended with the singular version of the included table name.">
	<cfargument name="distinct" type="boolean" required="false" default="false" hint="Whether to add the `DISTINCT` keyword to your `SELECT` clause. Wheels will, when necessary, add this automatically (when using pagination and a `hasMany` association is used in the `include` argument, to name one example).">
	<cfargument name="include" type="string" required="false" default="" hint="Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex `include` strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though.">
	<cfargument name="maxRows" type="numeric" required="false" default="-1" hint="Maximum number of records to retrieve. Passed on to the `maxRows` `cfquery` attribute. The default, `-1`, means that all records will be retrieved.">
	<cfargument name="page" type="numeric" required="false" default=0 hint="If you want to paginate records, you can do so by specifying a page number here. For example, getting records 11-20 would be page number 2 when `perPage` is kept at the default setting (10 records per page). The default, `0`, means that records won't be paginated and that the `perPage`, `count`, and `handle` arguments will be ignored.">
	<cfargument name="perPage" type="numeric" required="false" hint="When using pagination, you can specify how many records you want to fetch per page here. This argument is only used when the `page` argument has been passed in.">
	<cfargument name="count" type="numeric" required="false" default=0 hint="When using pagination and you know in advance how many records you want to paginate through, you can pass in that value here. Doing so will prevent Wheels from running a `COUNT` query to get this value. This argument is only used when the `page` argument has been passed in.">
	<cfargument name="handle" type="string" required="false" default="query" hint="Handle to use for the query in pagination. This is useful when you're paginating multiple queries and need to reference them in the @paginationLinks function, for example. This argument is only used when the `page` argument has been passed in.">
	<cfargument name="cache" type="any" required="false" default="" hint="If you want to cache the query, you can do so by specifying the number of minutes you want to cache the query for here. If you set it to `true`, the default cache time will be used (60 minutes).">
	<cfargument name="reload" type="boolean" required="false" hint="Set to `true` to force Wheels to query the database even though an identical query may have been run in the same request. (The default in Wheels is to get the second query from the request-level cache.)">
	<cfargument name="parameterize" type="any" required="false" hint="Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only.">
	<cfargument name="returnAs" type="string" required="false" hint="Set this to `objects` to return an array of objects. Set this to `query` to return a query result set.">
	<cfargument name="returnIncluded" type="boolean" required="false" hint="When `returnAs` is set to `objects`, you can set this argument to `false` to prevent returning objects fetched from associations specified in the `include` argument. This is useful when you only need to include associations for use in the `WHERE` clause only and want to avoid the performance hit that comes with object creation.">
	<cfargument name="callbacks" type="boolean" required="false" default="true" hint="You can set this argument to `false` to prevent running the execution of callbacks for a method call.">
	<cfargument name="includeSoftDeletes" type="boolean" required="false" default="false" hint="You can set this argument to `true` to include soft-deleted records in the results.">
	<cfargument name="$limit" type="numeric" required="false" default=0>
	<cfargument name="$offset" type="numeric" required="false" default=0>
	<cfscript>
		var loc = {};
		$args(name="findAll", args=arguments);
		// we only allow direct associations to be loaded when returning objects
		if (application.wheels.showErrorInformation && Len(arguments.returnAs) && arguments.returnAs != "query" && Find("(", arguments.include) && arguments.returnIncluded)
			$throw(type="Wheels", message="Incorrect Arguments", extendedInfo="You may only include direct associations to this object when returning an array of objects.");
		// count records and get primary keys for pagination
		if (arguments.page)
		{
			if (application.wheels.showErrorInformation && arguments.perPage lte 0)
				$throw(type="Wheels", message="Incorrect Argument", extendedInfo="The perPage argument should be a positive numeric value.");
			if (Len(arguments.order))
			{
				// insert primary keys to order clause unless they are already there, this guarantees that the ordering is unique which is required to make pagination work properly
				loc.compareList = $listClean(ReplaceNoCase(ReplaceNoCase(arguments.order, " ASC", "", "all"), " DESC", "", "all"));
				loc.iEnd = ListLen(primaryKeys());
				for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
				{
					loc.iItem = primaryKeys(loc.i);
					if (!ListFindNoCase(loc.compareList, loc.iItem) && !ListFindNoCase(loc.compareList, tableName() & "." & loc.iItem))
						arguments.order = ListAppend(arguments.order, loc.iItem);
				}
			}
			else
			{
				// we can't paginate without any order so we default to ascending ordering by the primary key column(s)
				arguments.order = primaryKey();
			}
			if (Len(arguments.include))
				loc.distinct = true;
			else
				loc.distinct = false;
			if (arguments.count gt 0)
				loc.totalRecords = arguments.count;
			else
				loc.totalRecords = this.count(where=arguments.where, include=arguments.include, reload=arguments.reload, cache=arguments.cache, distinct=loc.distinct, parameterize=arguments.parameterize, includeSoftDeletes=arguments.includeSoftDeletes);
			loc.currentPage = arguments.page;
			if (loc.totalRecords == 0)
			{
				loc.totalPages = 0;
				loc.returnValue = "";
			}
			else
			{
				loc.totalPages = Ceiling(loc.totalRecords/arguments.perPage);
				loc.limit = arguments.perPage;
				loc.offset = (arguments.perPage * arguments.page) - arguments.perPage;
				// if the full range of records is not requested we correct the limit to get the exact amount instead
				// for example if totalRecords is 57, limit is 10 and offset 50 (i.e. requesting records 51-60) we change the limit to 7
				if ((loc.limit + loc.offset) gt loc.totalRecords)
					loc.limit = loc.totalRecords - loc.offset;
				if (loc.limit < 1)
				{
					// if limit is 0 or less it means that a page that has no records was asked for so we return an empty query
					loc.returnValue = "";
				}
				else
				{
					loc.values = findAll($limit=loc.limit, $offset=loc.offset, select=primaryKeys(), where=arguments.where, order=arguments.order, include=arguments.include, reload=arguments.reload, cache=arguments.cache, distinct=loc.distinct, parameterize=arguments.parameterize, includeSoftDeletes=arguments.includeSoftDeletes);
					if (loc.values.RecordCount)
					{
						loc.paginationWhere = "";
						for (loc.k=1; loc.k <= loc.values.RecordCount; loc.k++)
						{
							loc.keyComboValues = [];
							loc.iEnd = ListLen(primaryKeys());
							for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
							{
								loc.property = primaryKeys(loc.i);
								ArrayAppend(loc.keyComboValues, "#tableName()#.#loc.property# = #variables.wheels.class.adapter.$quoteValue(str=loc.values[loc.property][loc.k], type=validationTypeForProperty(loc.property))#");
							}
							loc.paginationWhere = ListAppend(loc.paginationWhere, "(" & ArrayToList(loc.keyComboValues, " AND ") & ")", Chr(7));
 						}
						loc.paginationWhere = Replace(loc.paginationWhere, Chr(7), " OR ", "all");
 						if (Len(arguments.where) && Len(arguments.include)) // this can be improved to also check if the where clause checks on a joined table, if not we can use the simple where clause with just the ids
 							arguments.where = "(#arguments.where#) AND (#loc.paginationWhere#)";
 						else
						{
							arguments.where = loc.paginationWhere;
						}
					}
				}
			}
			// store pagination info in the request scope so all pagination methods can access it
			setPagination(loc.totalRecords, loc.currentPage, arguments.perPage, arguments.handle);
		}
		if (StructKeyExists(loc, "returnValue") && !Len(loc.returnValue))
		{
			if (arguments.returnAs == "query")
			{
				loc.returnValue = QueryNew("");
			}
			else if (singularize(arguments.returnAs) == arguments.returnAs)
			{
				loc.returnValue = false;
			}
			else
			{
				loc.returnValue = ArrayNew(1);
			}
		}
		else if (!StructKeyExists(loc, "returnValue"))
		{
			// make the where clause generic for use in caching
			loc.originalWhere = arguments.where;
			arguments.where = REReplace(arguments.where, variables.wheels.class.RESQLWhere, "\1?\8" , "all");
			// get info from cache when available, otherwise create the generic select, from, where and order by clause
			loc.queryShellKey = $hashedKey(variables.wheels.class.modelName, arguments);
			loc.sql = $getFromCache(loc.queryShellKey, "sql");
			if (!IsArray(loc.sql))
			{
				loc.sql = [];
				ArrayAppend(loc.sql, $selectClause(select=arguments.select, include=arguments.include, returnAs=arguments.returnAs));
				ArrayAppend(loc.sql, $fromClause(include=arguments.include, includeSoftDeletes=arguments.includeSoftDeletes));
				loc.sql = $addWhereClause(sql=loc.sql, where=loc.originalWhere, include=arguments.include, includeSoftDeletes=arguments.includeSoftDeletes);
				loc.groupBy = $groupByClause(select=arguments.select, group=arguments.group, include=arguments.include, distinct=arguments.distinct, returnAs=arguments.returnAs);
				if (Len(loc.groupBy))
				{
					ArrayAppend(loc.sql, loc.groupBy);
				}
				loc.orderBy = $orderByClause(order=arguments.order, include=arguments.include);
				if (Len(loc.orderBy))
				{
					ArrayAppend(loc.sql, loc.orderBy);
				}
				$addToCache(key=loc.queryShellKey, value=loc.sql, category="sql");
			}
			// add where clause parameters to the generic sql info
			loc.sql = $addWhereClauseParameters(sql=loc.sql, where=loc.originalWhere);
			// return existing query result if it has been run already in current request, otherwise pass off the sql array to the query
			loc.queryKey = $hashedKey(variables.wheels.class.modelName, arguments, loc.originalWhere);
			if (application.wheels.cacheQueriesDuringRequest && !arguments.reload && StructKeyExists(request.wheels, loc.queryKey))
			{
				loc.findAll = request.wheels[loc.queryKey];
			}
			else
			{
				loc.finderArgs = {};
				loc.finderArgs.sql = loc.sql;
				loc.finderArgs.maxRows = arguments.maxRows;
				loc.finderArgs.parameterize = arguments.parameterize;
				loc.finderArgs.limit = arguments.$limit;
				loc.finderArgs.offset = arguments.$offset;
				loc.finderArgs.$primaryKey = primaryKeys();
				loc.cachedQry = false;
				if (application.wheels.cacheQueries && (IsNumeric(arguments.cache) || (IsBoolean(arguments.cache) && arguments.cache)))
				{
					//memory still needs cachewithin as that is the current CFWHeels implementation
					if (application.cacheonwheels.storage == "memory") {
						loc.finderArgs.cachedWithin = $timeSpanForCache(arguments.cache);
					} else {
						//Get the value out of the cache first
						loc.findAll = $getFromCache(loc.queryKey);
						
						if (NOT loc.findAll) {
							loc.findAll = variables.wheels.class.adapter.$query(argumentCollection=loc.finderArgs);
							$addToCache($hashedKey(loc.findAll.query), loc.findAll);
							loc.cachedQry = true;
						}
					}
				}
				
				if (NOT loc.cachedQry) {
					loc.findAll = variables.wheels.class.adapter.$query(argumentCollection=loc.finderArgs);
				}
				request.wheels[loc.queryKey] = loc.findAll; // <- store in request cache so we never run the exact same query twice in the same request
			}
			request.wheels[$hashedKey(loc.findAll.query)] = variables.wheels.class.modelName; // place an identifer in request scope so we can reference this query when passed in to view functions
			switch (arguments.returnAs)
			{
				case "query":
				{
					loc.returnValue = loc.findAll.query;
					// execute callbacks unless we're currently running the count or primary key pagination queries (we only want the callback to run when we have the actual data)
					if (loc.returnValue.columnList != "wheelsqueryresult" && !arguments.$limit && !arguments.$offset)
						$callback("afterFind", arguments.callbacks, loc.returnValue);
					break;
				}
				case "struct": case "structs":
				{
					loc.returnValue = $serializeQueryToStructs(query=loc.findAll.query, argumentCollection=arguments);
					break;
				}
				case "object": case "objects":
				{
					loc.returnValue = $serializeQueryToObjects(query=loc.findAll.query, argumentCollection=arguments);
					break;
				}
				default:
				{
					if (application.wheels.showErrorInformation)
						$throw(type="Wheels.IncorrectArgumentValue", message="Incorrect Arguments", extendedInfo="The `returnAs` may be either `query`, `struct(s)` or `object(s)`");
					break;
				}
			}
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>
	
</cfcomponent>