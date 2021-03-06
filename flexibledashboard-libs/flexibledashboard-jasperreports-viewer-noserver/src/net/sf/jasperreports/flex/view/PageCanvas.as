/*
 * ============================================================================
 * GNU Lesser General Public License
 * ============================================================================
 *
 * JasperReports - Free Java report-generating library.
 * Copyright (C) 2001-2006 JasperSoft Corporation http://www.jaspersoft.com
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA.
 * 
 * JasperSoft Corporation
 * 303 Second Street, Suite 450 North
 * San Francisco, CA 94107
 * http://www.jaspersoft.com
 */

/*
 * Contributors:
 * Victor Kolesnikov - gladman4@gmail.com
 */

package net.sf.jasperreports.flex.view
{
	import mx.containers.Canvas;
	import mx.events.FlexEvent;
	
	import net.sf.jasperreports.flex.draw.PageDrawer;
	import net.sf.jasperreports.flex.model.Page;
	import net.sf.jasperreports.flex.xml.PageFactory;

	public class PageCanvas extends Canvas
	{
		private var xml:XML;
		private var pageIndex:int;

		public function PageCanvas(xml:XML, pageIndex:int)
		{
			this.xml = xml;
			this.pageIndex = pageIndex;

			addEventListener(FlexEvent.INITIALIZE, initializeHandler);
		}

		private function initializeHandler(event:FlexEvent):void
		{
			paint();
		}

		private function paint():void
		{
			var page:Page = PageFactory.create(xml, pageIndex);
			PageDrawer.draw(this, page);
		}
	}

}
