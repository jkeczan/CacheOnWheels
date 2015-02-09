<h2>
	Statistics
</h2>

<cfset stats = application.cacheonwheels.cache.getStats() />
<cfset statKeys = StructKeyList( stats ) />

<table style="width:100%;" >
	<tbody>
		<cfoutput>
			<cfloop collection="#stats#"
			        item="item" >
				<cfif IsStruct( stats[item] ) >
					<cfset innerStruct = stats[item] />
					<tr>
						<td colspan="3"
						    class="stat-header" >
							<b>
								#item#
							</b>
						</td>
					</tr>
					<cfloop collection="#innerStruct#"
					        item="innerItem" >
						<tr>
							<td style="width:30%" >
								<b>
									#Humanize( innerItem )#
								</b>
							</td>
							<td>
								#innerStruct[innerItem]#
							</td>
						</tr>
					</cfloop>
				<cfelse>
					<tr>
						<td>
							#Humanize( item )#
						</td>
						<td>
							#stats[item]#
						</td>
					</tr>
				</cfif>
			</cfloop>
		</cfoutput>
	</tbody>
</table>