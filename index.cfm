<style>
	tr:nth-child(even) {background: #CCC}
	tr:nth-child(odd) {background: #FFF}
	.baseWheelsColor {
	color:#B00701;
	}
	.stat-header {
	background-color:#444;
	color:#fff;
	}
</style>

<h1>
	Cache On Wheels
</h1>
<p>
	Cache on wheels is a plugin designed to extend
	the caching framework of CFWheels to include
	external sources.
	The current plugin can handle memory(cfwheels
	default) and memcached our of the box. 
</p>
<cfoutput>
	<table>
		<tr>
			<td>
				#linkTo(text="Home", params="view=plugins&name=cacheonwheels&event=home")#
			</td>
			<td>
				#linkTo(text="Stats", params="view=plugins&name=cacheonwheels&event=stats")#
				
			</td>
			<td>
				#linkTo(text="Storage", params="view=plugins&name=cacheonwheels&event=storage")#
			</td>
			<td>
				#linkTo(text="Functions", params="view=plugins&name=cacheonwheels&event=documentation")#
			</td>
			<td>
				#linkTo(text="Add Your Own Storage", params="view=plugins&name=cacheonwheels&event=addStorage")#
			</td>
		</tr>
	</table>
</cfoutput>
<cfparam name="URL.event"
         default="home" />

<cfinclude template="#URL.event#.cfm" />