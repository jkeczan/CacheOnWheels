<h3>How to Add You Own Storage</h3>
<p>Adding your own storage to Cache on Wheels is really easy. All you have to do is follow these simple steps and you will be caching to your datasource in no time!</p>

<ol>
	<li>Create a <code>storage</code> directory the root of your cfwheels website</li>
	<li>Create a a CFC in the storage directory that implements <code>cache.storage.AbstractStorage</code> and extends <code>BaseStorage</code><br />
<pre><code>&lt;cfcomponent implements="AbstractStorage" extends="BaseStorage"&gt;
	&lt;cffunction name="init" &gt;
		
	&lt;/cffunction&gt;
&lt;/cfcomponent&gt;</code></pre>
	</li>
	<li>
		The Abstract interface will implement the following functions. You must implement them exactly how they are:
		<p>NOTE: The <code>default</code> argument in the <code>ARGUMENTS</code> struct is dynamic for each function and is the only variable that can be different than the interface declaration</p>
	<pre><code>&lt;cffunction name="add" access="public" returntype="void" &gt;
	&lt;cfargument name="key" required="true" type="string" /&gt; 
	&lt;cfargument name="value" required="true" type="any" /&gt; 
	&lt;cfargument name="time" type="numeric" required="false" /&gt;
	&lt;cfargument name="category" type="string" required="false"  /&gt;
	&lt;cfargument name="currentTime" type="date" required="false" /&gt;
&lt;/cffunction&gt;

&lt;cffunction name="get" access="public" returntype="any"&gt;
	&lt;cfargument name="key" required="true" type="string" /&gt; 
	&lt;cfargument name="category" type="string" required="false"&gt;
	&lt;cfargument name="currentTime" type="date" required="false"&gt;
&lt;/cffunction&gt;

&lt;cffunction name="isAvailable" access="public" returntype="boolean" &gt;
	
&lt;/cffunction&gt;

&lt;cffunction name="delete" access="public" returntype="void" &gt;
	&lt;cfargument name="key" required="true" type="string" /&gt; 
	&lt;cfargument name="category" required="false" type="string"&gt;
&lt;/cffunction&gt;

&lt;cffunction name="clear" access="public" returntype="void" &gt;
	&lt;cfargument name="category" required="false" type="string"  /&gt; 
&lt;/cffunction&gt;

&lt;cffunction name="getStats" access="public" returntype="Any" &gt;
	
&lt;/cffunction&gt;</code></pre>
	</li>
	<li>
		After you have implemented your storage option. Go to settings and override the <code>application.cacheonwheels.storage</code> property with the name of the storage option
		you created in all lowercase. 
	</li>
	<li>
		Your new storage option should now be setup
	</li>
</ol>