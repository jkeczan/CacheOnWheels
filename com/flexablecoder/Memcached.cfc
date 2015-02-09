<cfcomponent  extends="_base"  output="false">

	<!-----------
		This memcached client uses the java memcached client written by Dustin Sallings found at:
			http://bleu.west.spy.net/~dustin/projects/memcached/
		it also borrows from the javaloader project put together by mark mandel
			http://www.transfer-orm.com/?action=javaloader.index
		This project was also inspired by the previous memcached client put together by shayne sweeney
			http://memcached.riaforge.org/
		
		you can find this project at 
			http://cfmemcached.riaforge.org/
		And if you feel like visiting my personal blog (Jon Hirschi), it can be found at:
			http://www.flexablecoder.com
		Wow, that's a mouthful...  
		
	------------->
	
	<cfset variables.storedScope="server">
	<cfset variables.servers = "">
	<!----------
		These variables are set in the base... 
		
	<cfset variables.DefaultTimeunit = "">
	<cfset variables.defaultRequestTimeout = 5>
	------->
	
	
	<cffunction name="init" displayname="init" hint="init function" access="public" output="false" returntype="any">
		<cfargument name="servers" type="string" required="true" />
		<cfargument name="storedScope" type="string" required="false" default="server">
		<cfargument name="defaultRequestTimeout" type="numeric" required="false" default="10">
		<cfargument name="defaultTimeUnit" type="string" required="false" default="SECONDS">

		<cfscript>
			/*
				if you want to use the java loader you don't have to do anything, just put this into a location under
				your web root and it will load all the classes for you.  if you don't want to use the java loader, 
				just comment out the classes below and comment in the lines that are commented out. if you don't want
				to use the java loader, then you will need to put the classes somewhere on the class path.
				generally an easy place to put this is in the <cfroot>/lib directory.
			*/
			// if you are having problems loading the memcached client or
			// if it is giving you errors saying that it can't find one of 
			// the java classes, then you can change this value here to point to the directory
			// where the java classes are located. in this case they are in the lib directory,
			// just below the directory where this memcached client is placed.  if you have 
			// copied the java libs into the java class path, then you can change this to 
			// an empty directory.
			
			setServers(arguments.servers);
			setStoredScope(arguments.storedScope);
			
			/*
			var thisDefaultTimeUnit = createObject("java","java.util.concurrent.TimeUnit"); 
			if (arguments.defaultTimeUnit eq "seconds")	{
				setDefaultTimeUnit(thisDefaultTimeUnit.SECONDS);
			} else if (arguments.defaultTimeUnit eq "MINUTES") {
				// Don't do this... would probably be bad;
				setDefaultTimeUnit(thisDefaultTimeUnit.MINUTES);				
			} else {
				setDefaultTimeUnit(thisDefaultTimeUnit.MILLISECONDS);
			}
			*/
			
			/*
			var MemcachedClientJavaJarDir = "#GetDirectoryFromPath(GetCurrentTemplatePath())#lib";
			// these lines to use if you want to use the java loader
			var facadeFactory = createObject("component", "facade.FacadeFactory").init();
			var javaLoader = createObject("component", "util.JavaLoader").init(facadeFactory.getServerFacade(),MemcachedClientJavaJarDir);			
			
			variables.servers = arguments.servers;
			
			variables.addrUtil = javaLoader.create("net.spy.memcached.AddrUtil").init();
			variables.memcached = javaLoader.create("net.spy.memcached.MemcachedClient").init(addrUtil.getAddresses(arguments.servers));
			variables.transcoder = variables.memcached.getTranscoder();
			
			// these lines to use if you don't want to use the java loader
			variables.addrUtil = createObject("java","net.spy.memcached.AddrUtil").init();
			variables.memcached = createObject("java","net.spy.memcached.MemcachedClient").init(addrUtil.getAddresses(arguments.servers));
			variables.timeUnit = createObject("java","java.util.concurrent.TimeUnit");
			*/
	
			/* ***************************
				some methods return a future object (especially asyncronous sets and gets)
				these let you check back in on the result.  they don't require that you wait around for 
				a response
				
				future object methods:
					Cancel() - returns a boolean - allows you to cancel the operation
					get( int, variables.timeunit ) - returns object - when an interger is sent in, you can 
							get the result in that amount of time.
					get() - returns an object - get the result when it is available.
					isCancelled() -  returns boolean - lets you know if the operation was cancelled
					isDone() - returns boolean - returns true when the operation has finished.
			
				Just a little caveat here.  keys are case sensitive, so make sure that you have the right case...
			*/
			super.init(argumentCollection=arguments);
			
			getMemcachedInstance(reloadlib=true);
		</cfscript>
		<cfreturn this>
	</cffunction>

	<cffunction name="add" displayname="add" access="public" output="false" returntype="any"
			hint="Add an object to the cache iff it does not exist already. 
				Add an object to the cache iff it does not exist already. 
				The exp value is passed along to memcached exactly as given, and will be processed per 
				the memcached protocol specification: 

				The actual value sent may either be Unix time 
				(number of seconds since January 1, 1970, as a 32-bit value), 
				or a number of seconds starting from current time. 
				In the latter case, this number of seconds may not 
				exceed 60*60*24*30 (number of seconds in 30 days); 
				if the number sent by a client is larger than that, the server will consider it to be 
				real Unix time value rather than an offset from current time. 
				
				RETURNS: a future representing the processing of this operation

			" >
		<cfargument name="key" type="string" hint="a single key to add" required="true" />
		<cfargument name="value" type="any" hint="the value to set" required="true" />
		<cfargument name="expiry" type="numeric" hint="number of seconds until expire" default="0" required="true" />
		<cfscript>
			var futureTask = "";
			var ret = "";
			try {
				ret = getMemcached().add(arguments.key, arguments.expiry, super.serialize(arguments.value) );
			} catch (Any e)	{
				// failing gracefully
				writelog("add failed for #arguments.Key#. #e.message# #e.detail#","ERROR",false,"memcached");
			}
			if (not isnull(ret) and isObject(ret))	{
				futureTask = createObject("component","FutureTask").init(ret);
				checkFutureDone(futureTask);
			}
		</cfscript>
		<cfreturn futureTask/>
	</cffunction>

	<cffunction name="asyncGet" access="public" output="false" returntype="Any"
		hint="Get the given key asynchronously. returns the future value of those keys
			what you get back wht you use this function is an object that has the future value
			of the key you asked to retrieve.  You can check at anytime to see if the value has been
			retrieved by using the  ret.isDone() method. once you get a true from that value, you 
			need to then call the ret.get() function.  
			">
		<cfargument name="key" type="string" hint="given a key, get the key asnycronously" required="true" />
		<cfscript>
			var ret = "";
			var futureTask ="";
			// gotta go through all this to catch the nulls.
			try	{
				ret = getMemcached().asyncGet(arguments.key);
				// additional processing might be required.
			} catch(Any e)	{
				// failing gracefully
				writelog("asyncGet failed for #arguments.Key#. #e.message# #e.detail#","ERROR",false,"memcached");
			}
			if (not isnull(ret) and isObject(ret))	{
				futureTask = createObject("component","FutureTask").init(ret);
				checkFutureDone(futureTask);
			}
		</cfscript>
		<cfreturn futureTask/>
	</cffunction>

	<cffunction name="asyncGetBulk" access="public" output="false" returntype="any"
			hint="Asynchronously get a bunch of objects from the cache. returns the future value of those keys.  
				" >
		<cfargument name="keys" type="array" hint="given a struct of keys, get the keys asnycronously" required="true" />
		<cfscript>
			var ret = "";
			var futureTask = "";
			// gotta go through all this to catch the nulls.
			try	{
				ret = getMemcached().asyncGetBulk(arguments.keys);
				// additional processing might be required.
			} catch(Any e)	{
				// catch is here to fail gracefully
				writelog("asyncGetBulk failed for #arraytolist(arguments.Keys)#. #e.message# #e.detail#","ERROR",false,"memcached");
			}
			if (not isnull(ret) and isObject(ret))	{
				futureTask = createObject("component","FutureTask").init(ret);
				checkFutureDone(futureTask);
			}
		</cfscript>
		<cfreturn futureTask/>
	</cffunction>

	<cffunction name="decr" displayname="decr" access="public" output="false" returntype="Numeric"
			hint="Decrement the given key by the given value. returns the new value, or -1 if we were unable to decrement or add" >
		<cfargument name="key" type="string" hint="a single key to add" required="true" />
		<cfargument name="by" type="numeric" hint="amount to decrement by" default="0" required="false" />
		<cfargument name="value" type="numeric" hint="the value to set" required="false" default="0"/>
		<cfscript>
			var ret = -1;
			var futureTask = "";
			try {
				if ( structkeyExists(arguments,"value") )	{
					ret = getMemcached().decr(arguments.key,arguments.by,arguments.value);
				} else {
					ret = getMemcached().decr(arguments.key,arguments.by);
				}
			}  catch (Any e)	{
				// catch is here to fail gracefully
				ret = -1;
				writelog("decrement failed for #arguments.Key#. #e.message# #e.detail#","ERROR",false,"memcached");
			}
			if (not isnull(ret) and isObject(ret))	{
				futureTask = createobject("component","FutureTask").init(ret);
				checkFutureDone(futureTask);
			}
			
		</cfscript>
		<cfreturn ret/>
	</cffunction>

	<cffunction name="delete" access="public" output="true" returntype="any"
		hint="Shortcut to delete that will immediately delete the item from the cache. 
			or in the delay specified. returns a future object that allows you to 
			check back on the processing further if you choose." >
		<cfargument name="deletekey" type="string" required="true" hint="the key to delete"/>
		<cfargument name="delay" type="numeric" required="false" default="0" hint="when to delete the key - time in seconds" />
		<Cfscript>
			var ret = false;
			var futureTask = "";
			try 	{
				if (arguments.delay gt 0)	{
					ret = getMemcached().delete(arguments.deletekey,arguments.delay);
				} else {
					ret = getMemcached().delete(arguments.deletekey);
				}
			}  catch (Any e)	{
				// failing gracefully
				ret = "";
				writelog("delete failed for #arguments.deleteKey#. #e.message# #e.detail#","ERROR",false,"memcached");
			}
			if (not isnull(ret) and isobject(ret))	{
				futureTask = createobject("component","FutureTask").init(ret);
				checkFutureDone(futureTask);
			}  else {
				futureTask = createobject("component","FutureTask").init();
			}
		</Cfscript>
		<cfreturn futureTask/>
	</cffunction>

	<cffunction name="get" access="public" output="false" returntype="Any"
		hint=" Get with a single key.  waits for a return value" >
		<cfargument name="key" type="string" required="true" hint="given a key, get the key asnycronously" />
		<cfargument name="timeout" type="numeric" required="false" default="#getDefaultRequestTimeout()#" 
				hint="the number of milliseconds to wait until for the response.  
				a timeout setting of 0 will wait forever for a response from the server"/>
		<cfargument name="timeoutUnit" type="string" required="false" default="#getDefaultTimeUnit()#"
				hint="The timeout unit to use for the timeout"/>
		<cfscript>
			var ret = "";
			var futureTask = "";
			// gotta go through all this to catch the nulls.
			try 	{
				ret = getMemcached().asyncGet(arguments.key);	
				if (not isdefined("ret") )	{
					ret = "";
				} else {
					futureTask = createObject("component","FutureTask").init(ret);
					ret = futureTask.get(arguments.timeout,arguments.timeoutUnit);
				}
			} catch	(Any e) 	{
				// failing gracefully
				ret = "";
				writelog("get a value failed for #arguments.key#. #e.message# #e.detail#","ERROR",false,"memcached");
			}
			
		</cfscript>
		<cfreturn ret/>
	</cffunction>

	<cffunction name="getBulk" access="public" output="false" returntype="any"
		hint="Get the values for multiple keys from the cache. waits for a return value" >
		<cfargument name="keys" type="array" hint="given a key, get the key asnycronously" required="true" />
		<cfargument name="timeout" type="numeric" required="false" default="#getDefaultRequestTimeout()#" 
				hint="the number of milliseconds to wait until for the response.  
				a timeout setting of 0 will wait forever for a response from the server"/>
		<cfargument name="timeoutUnit" type="string" required="false" default="#getDefaultTimeUnit()#"
				hint="The timeout unit to use for the timeout"/>
		<cfscript>
			var ret = "";
			var futureTask = "";
			// gotta go through all this to catch the nulls.
			try {
				ret = getMemcached().asyncGetBulk(arguments.keys);
				if (not isdefined("ret") )	{
					ret = "";
				} else {
					futureTask = createObject("component","FutureTask").init(ret);
					ret = futureTask.get(arguments.timeout,arguments.timeoutUnit);
				}
			}  catch (Any e)	{
				// failing gracefully
				ret = "";
				writelog("getBulk failed a value failed. #e.message# #e.detail#","ERROR",false,"memcached");
			}
		</cfscript>
		<cfreturn ret/>
	</cffunction>

	<cffunction name="incr" access="public" output="false" returntype="Numeric"
		hint="Increment the given key by the given amount. returns -1 if string cannot be incremented">
		<cfargument name="key" type="string" hint="a single key to add" required="true" />
		<cfargument name="by" type="numeric" hint="amount to increment by" default="0" required="false" />
		<cfargument name="value" type="numeric" hint="the default value used if null" required="false"/>
		<cfscript>
			var ret = -1;
			
			try 	{
				if ( structkeyExists(arguments,"value") )	{
					ret = getMemcached().incr(arguments.key,arguments.by,arguments.value);
				} else {
					ret = getMemcached().incr(arguments.key,arguments.by);
				}
			} catch (Any e)	{
				// failing gracefully here
				writelog("Incrementing a value failed. #e.message# #e.detail#","ERROR",false,"memcached");
				ret = -1;
			}
		</cfscript>
		<cfreturn ret/>
	</cffunction>

	<cffunction name="doReplace" access="public" output="false" returntype="any"
		hint="Replace an object with the given value iff there is already a value for the given key.
			
			The exp value is passed along to memcached exactly as given, 
			and will be processed per the memcached protocol specification: 

			The actual value sent may either be Unix time (number of seconds since January 1, 1970, 
			as a 32-bit value), or a number of seconds starting from current time. 
			In the latter case, this number of seconds may not exceed 60*60*24*30 
			(number of seconds in 30 days); if the number sent by a client is larger than that, 
			the server will consider it to be real Unix time value rather than an offset from current time.
		
			RETURNS: a future representing the processing of the operation		
		" >
		<cfargument name="key" type="string" hint="a single key to add" required="true" />
		<cfargument name="value" type="any" hint="the value to set" required="true" />
		<cfargument name="expiry" type="numeric" hint="number of seconds until expire" default="0" required="true"/>
		<cfscript>
			var futureTask = "";
			var ret = "";
			try	{
				ret = getMemcached().replace(arguments.key,arguments.expiry,super.serialize(arguments.value));
			} catch (Any e)	{
				// failing gracefully
				ret = "";
				writelog("Replacing a value failed. #e.message# #e.detail#","ERROR",false,"memcached");
			}
			if (not isnull(ret) and isObject(ret))	{
				futureTask = createObject("component","FutureTask").init(ret);
				checkFutureDone(futureTask);
			}
		</cfscript>
		<cfreturn futureTask/>
	</cffunction>

	<cffunction name="set" access="public" output="false" returntype="any"
		hint="Set an object in the cache regardless of any existing value.
			Set an object in the cache regardless of any existing value. 
			The exp value is passed along to memcached exactly as given, 
			and will be processed per the memcached protocol specification: 

			The actual value sent may either be Unix time (number of seconds since January 1, 1970, 
			as a 32-bit value), or a number of seconds starting from current time. 
			In the latter case, this number of seconds may not exceed 60*60*24*30 
			(number of seconds in 30 days); if the number sent by a client is larger than that, 
			the server will consider it to be real Unix time value rather than an offset from current time.
		
			RETURNS: a future Task representing the processing of the operation
		" >
		<cfargument name="key" type="string" hint="a single key to add" required="true" />
		<cfargument name="value" type="any" hint="the value to set" required="true" />
		<cfargument name="expiry" type="numeric" hint="number of seconds until expire" default="0" required="true"/>
		<cfscript>
			var futureTask = "";
			var ret = "";
			try 	{
				ret = getMemcached().set(arguments.key,arguments.expiry,super.serialize(arguments.value));
			}  catch (Any e)	{
				// failing gracefully
				ret = "";
				writelog("Setting a value failed. #e.message# #e.detail#","ERROR",false,"memcached");
			}
			if (not isnull(ret) and isObject(ret))	{
				futureTask = createObject("component","FutureTask").init(ret);
				checkFutureDone(futureTask);
			}
			//writedump(futureTask);
			//writedump(futureTask.isDone());
			//abort;
		</cfscript>
		<cfreturn futureTask/>
	</cffunction>

	<!------------------ public util functions ------------------>
	
	<cffunction name="concatArrayQueries" access="public" returntype="any" output="false"
		hint="this will return either full query or an empty string if no queries are found.
			in the case of sending in an array full of null values, it will return an empty string" >
		<cfargument name="arrQueries" required="true" type="array">
		<cfscript>
			var mainQuery = "";
			var arrColumns = "";
			var ColumnLength = "";
			var i = 1;
			var j = 1;
			var currentRow = 1;
			
			for (i=1;i lte arrayLen(arrQueries);i=i+1)	{
				if (isQuery(arrQueries[i]) and isQuery(mainQuery))	{
					currentRow = queryAddRow(mainQuery,1);
					for (j=1; j lte columnLength;j=j+1)	{
						mainQuery[arrColumns[j]][currentRow] = arrQueries[i][arrColumns[j]][1];
					}
				} else if ( isQuery(arrQueries[i]) )	{
					mainQuery = duplicate(arrQueries[i]);
					arrColumns = listToArray(mainQuery.columnList);
					ColumnLength = arrayLen(arrColumns);
				}
			}
		</cfscript>
		<cfreturn mainQuery>
	</cffunction>
	
	<cffunction name="concatStructQueries" access="public" returntype="any" output="false" 
		hint="this will return either full query or an empty string if no queries are found.
			in the case of sending in an array full of null values, it will return an empty string" >
		<cfargument name="structQueries" required="true" type="struct">
		<cfscript>
			var arrKeys = listtoarray(structKeyList(structQueries));
			var mainQuery = "";
			var arrColumns = "";
			var ColumnLength = "";
			var i = 1;
			var j = 1;
			var x = 0;
			var currentRow = 1;
			var currentQuery = "";
			
			for (i=1;i lte arrayLen(arrKeys);i=i+1)	{
				if (isQuery(structQueries[arrKeys[i]]) and isQuery(mainQuery))	{
					currentQuery = structQueries[arrKeys[i]];
					if (currentQuery.recordcount gt 0)	{
						currentRow = mainQuery.recordcount;
						queryAddRow(mainQuery,currentQuery.recordcount);
						for (x=1; x lte currentQuery.recordcount;x++)	{
							for (j=1; j lte columnLength;j=j+1)	{
								mainQuery[arrColumns[j]][currentRow+x] = currentQuery[arrColumns[j]][x];
							}
						}
					}
				} else if ( isQuery(structQueries[arrKeys[i]]) )	{
					mainQuery = duplicate(structQueries[arrKeys[i]]);
					arrColumns = listToArray(mainQuery.columnList);
					ColumnLength = arrayLen(arrColumns);
				}
			}
		</cfscript>
		<cfreturn mainQuery>
	</cffunction>
	
	
	<Cffunction name="concatQueries" access="public" output="false" returntype="query"
			hint="queries need to be exactly the same">
		<cfargument name="query1" type="query" required="true">
		<cfargument name="query2" type="query" required="true">
		<cfargument name="arrColumns" type="array" required="false" default="#listToArray(Query1.columnList)#">
		<Cfscript>
			var columnLength = arrayLen(arrColumns);
			var currentRow = queryAddRow(query1,1);
			var i=0;
			var j=0;
			for (i=1; i lte query2.recordcount;i=i+1)	{
				for (j=1; j lte columnLength;j=j+1)	{
					query1[arrColumns[j]][currentRow] = query2[arrColumns[j]][i];
				}
			}
		</Cfscript>
		<cfreturn query1>
	</Cffunction>
	
	<cffunction name="createMemcachedKey" returnType="string" output="yes" access="public" 
		hint="create a key from a struct of input arguments">
		<cfargument name="keyStruct" type="struct" required="true">
		<cfargument name="prefix" type="string" required="false" default="">	
		<cfscript>
			try{
				var cacheKey = "";
				var arrKeys = structkeyArray(arguments.keyStruct);
						
				arraySort(arrKeys,"textnocase");
				for(local.i=1;local.i<=ArrayLen(arrKeys);local.i++){
					if (structKeyExists(arguments.keystruct,arrKeys[i]))	{
						cacheKey = cacheKey.concat("#arrKeys[local.i]#=#arguments.keyStruct[arrKeys[local.i]]#");	
					}
				}
			}
			catch (any e){

				throw(message="Memcached.cfc createMemcachedKey(): #e.message#, #e.detail#", type="MEMCACHED", detail=e );
			}
			
			return arguments.prefix.concat(hash(cacheKey));
		</cfscript>
	</cffunction>


	<!-------------------- admin functions ----------------------->

	<cffunction name="getTranscoder" access="public" output="false" returntype="Any"
			hint="Get the current transcoder that's in use." >
		<cfreturn getMemCachedInstance().memcached.getTranscoder()/>
	</cffunction>

	<cffunction name="setTranscoder" access="public" output="false" returntype="void"
		hint="Set the transcoder for managing the cache representations of objects going in and out of the cache." >
		<cfargument name="transcoder" required="true" type="any" hint="Must be a transcoder object">
		<cfset var memStruct = getMemcachedInstance()>
		<cfset memStruct.memcached.setTranscoder(arguments.transcoder)>
		<cfset memStruct.Transcoder = arguments.Transcoder>
	</cffunction>

	<cffunction name="flush" access="public" output="false" returntype="any"
		hint="Flush all caches from all servers immediately or with a delay which is provided." >
		<cfargument name="delay" type="numeric" required="false" default="0" hint="Integer value - time in seconds to delay flushing cache">
		<cfscript>
			var ret = true;
			if (arguments.delay gt 0)	{
				ret = getMemcached().flush(javacast("long",arguments.delay));
			} else {
				ret = getMemcached().flush();
			}
		</cfscript>
		<cfreturn ret/>
	</cffunction>

	<cffunction name="run" access="public" output="true" returntype="void"
		hint="Infinitely loop processing IO. what can we use this for?" >
		<cfreturn getMemcached().run()/>
	</cffunction>

	<cffunction name="shutdown" access="public" output="false" returntype="boolean"
		hint="Shut down this client.">
		<cfargument name="timeout" required="false" type="numeric" default="0" hint="Integer number of units which to wait for the queue to die down">
		<cfargument name="timeUnit" required="false" type="any" hint="a time unit object - java.util.concurrent.TimeUnit" default="#getDefaultTimeunit()#">
		<cfscript>
			var ret = true;
			if (arguments.timeout gt 0)	{
				ret = getMemcached().shutdown(javacast("long",arguments.timeout),arguments.timeUnit);
			} else {
				ret = getMemcached().shutdown();
			}
		</cfscript>
		<cfreturn ret/>
	</cffunction>

	<cffunction name="waitForQueues" access="public" output="false" returntype="boolean"
		hint="Wait for the queues to die down." >
		<cfargument name="timeout" required="true" type="numeric" default="0" hint="Integer number of units which to wait for the queue to die down">
		<cfargument name="timeUnit" required="true" type="any" default="#getDefaultTimeUnit()#" hint="a time unit object ">
		<cfscript>
			var ret = true;
			ret = getMemcached().waitForQueues(javacast("long",arguments.timeout),arguments.timeUnit);
		</cfscript>
		<cfreturn ret/>
	</cffunction>

	<cffunction name="getVersions" access="public" output="false" returntype="struct"
		hint="Get the versions of all of the connected memcacheds. struct comes back as ">
		<!----------- there is a problem in here that if memcached is not running, this will hang 
			this is a known problem with the underlying java client - which should be addressed soon.
		------>
		<cfset var myVersions = getMemcached().getVersions()>
		<cfset var ret = StructNew()>
		<cfif not isnull(myVersions)>
			<!------- checking isdefined here, just incase we get a java null back ---->
			<cfset ret = toStruct(myVersions)>
		</cfif>
		<cfreturn ret/>
	</cffunction>
	
	<cffunction name="getStats" access="public" output="false" returntype="any"
			hint="get all of the stats from all of the connections">
		<!----------- there is a problem in here that if memcached is not running, this will hang 
			this is a known problem with the underlying java client which should be addressed soon.
		------>
		<cfset var myStats = getMemcached().getStats()>
		<cfset var ret = StructNew()>
		<cfif not isnull(myStats)>
			<!------- checking isdefined here, just incase we get a java null back ---->
			<cfset ret = toStruct(myStats)>
		</cfif>
		<cfreturn ret/>
	</cffunction>
	
	<cffunction name="stats" access="public" output="false" returntype="any"
			hint="get all of the stats from all of the connections">
		<!----------- there is a problem in here that if memcached is not running, this will hang 
			this is a known problem with the underlying java client which should be addressed soon.
		
			this function here for compatability with other memcached client.
		------>
		<cfreturn getStats()/>
	</cffunction>
	<!------------------ private util functions ------------------>
	
	<cffunction name="dateAddSeconds" access="private" output="false" returntype="date"
		hint="Converts a given number (seconds) to a future date-time.">
		<cfargument name="seconds" required="true" />
		<cfreturn DateAdd("s", arguments.seconds, Now()) />
	</cffunction>
			
	<cffunction name="toStruct" returntype="struct" access="private" output="false" hint="converts a java hashmap into a usable struct">
		<cfargument name="hashMap" type="Any" required="true"> 
		<!------- thanks to Ken Kolodziej for this snippet of code.  it works great! -------->
		<cfscript>
			var theStruct = structNew();
			var key = "";
			var newStructKey = ""; 
			var keys = arguments.hashMap.keySet();
			var iter = keys.Iterator();
			
			while(iter.HasNext()) {
				key = iter.Next();
				newStructKey = key.toString();
				theStruct[newStructKey] = arguments.hashMap.get(key);
			}
		</cfscript>
		<cfreturn theStruct>
	</cffunction>

	
	<cffunction name="makeMemcachedInstance" access="private" output="false" hint="this makes a memcached instance" returntype="struct">
		<cfargument name="servers" type="string" required="true">
		<cfscript>
			var memStruct = structNew();
			
			var MemcachedClientJavaJarDir = "#GetDirectoryFromPath(GetCurrentTemplatePath())#lib";
			// these lines to use if you want to use the java loader
			var facadeFactory = createObject("component", "facade.FacadeFactory").init();
			var javaLoader = createObject("component", "util.JavaLoader").init(facadeFactory.getServerFacade(),MemcachedClientJavaJarDir);			
			
			
			memStruct.addrUtil = javaLoader.create("net.spy.memcached.AddrUtil");
			memStruct.memcached = javaLoader.create("net.spy.memcached.MemcachedClient").init(memStruct.addrUtil.getAddresses(arguments.servers));
			/*
			// these lines to use if you don't want to use the java loader
			variables.addrUtil = createObject("java","net.spy.memcached.AddrUtil").init();
			variables.memcached = createObject("java","net.spy.memcached.MemcachedClient").init(addrUtil.getAddresses(arguments.servers));
			variables.timeUnit = createObject("java","java.util.concurrent.TimeUnit");
			*/
			memStruct.servers = arguments.servers;
			memStruct.transcoder = memStruct.memcached.getTranscoder();
		
		</cfscript>
		<cfreturn memStruct>
	</cffunction>
	
	
	<cffunction name="getMemcachedInstance" access="private" output="false" hint="this gets the actual memcached instance">
		<cfargument name="reloadLib" type="boolean" default="false" required="false">
		<cfscript>
			var myScope = getScope(getStoredScope());
			var makeMemcached = false;
			
			if (structKeyExists(myScope,"memStruct") and isStruct(myScope.memStruct) 
				and structKeyExists(myScope.memStruct,"memcached")
				and StructKeyExists(myScope.memStruct,"servers"))	{
				
				if (myScope.memStruct.servers eq getServers() and not arguments.reloadlib)	{
					return myScope.memstruct;
				} else {
					// need to shutdown the existing memcached instance
					// then start up a new instance;
					
					makeMemcached = true;
				}
			} else {
				makeMemcached = true;
			}

		</cfscript>
		
		<cfif makeMemcached>
			<cflock type="exclusive" name="makeMemcachedInstance" timeout="10">
				<cfscript>
					if (structKeyExists(myscope,"memStruct") and isStruct(myScope.memStruct) and structKeyExists(myScope.memStruct,"memcached"))	{
						
						myScope.memStruct.memcached.shutdown(200,createObject("java","java.util.concurrent.TimeUnit").MILLISECONDS);
					}
					var memStruct = makeMemcachedInstance(getServers());
					myScope['memStruct'] = memStruct;
					return memStruct;
				</cfscript>
			</cflock>
		</cfif>
	</cffunction>
	
	<cffunction name="getScope" access="private" output="false" returnType="struct" hint="this just returns a reference to the named scope">
		<Cfargument name="scopeName" type="string" required="true">
		<cfif arguments.scopeName eq "server">
			<cfreturn server>
		<cfelseif arguments.scopeName eq "application">
			<cfreturn application>
		<cfelse>
			<cfreturn server>
		</cfif>
	</cffunction>
	
	<cffunction name="getMemcached"	access="private" output="false" returntype="any" hint="this returns a java memcached instance">
		<cfscript>
			return getmemcachedInstance().memcached;
		</cfscript>	
	</cffunction> 	
	

	
	
	<!---------- setters and getters --------->
	
	<cffunction name="setServers" access="public" output="false" returntype="void">
		<cfargument name="Servers" type="any" required="true" />
		<cfset variables.Servers = arguments.Servers />
	</cffunction>
	
	<cffunction name="getServers" access="public" output="false" returntype="any">
		<cfreturn variables.Servers />
	</cffunction>
	
	<cffunction name="setStoredScope" access="public" output="false" returntype="void">
		<cfargument name="StoredScope" type="any" required="true" />
		<cfset variables.StoredScope = arguments.StoredScope />
	</cffunction>
	
	<cffunction name="getStoredScope" access="public" output="false" returntype="any">
		<cfreturn variables.StoredScope />
	</cffunction>
	
</cfcomponent>