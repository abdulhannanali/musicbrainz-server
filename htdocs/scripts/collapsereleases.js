/*----------------------------------------------------------------------------\
|                              Musicbrainz.org                                |
|                 Copyright (c) 2005 Stefan Kestenholz (keschte)              |
|-----------------------------------------------------------------------------|
| This software is provided "as is", without warranty of any kind, express or |
| implied, including  but not limited  to the warranties of  merchantability, |
| fitness for a particular purpose and noninfringement. In no event shall the |
| authors or  copyright  holders be  liable for any claim,  damages or  other |
| liability, whether  in an  action of  contract, tort  or otherwise, arising |
| from,  out of  or in  connection with  the software or  the  use  or  other |
| dealings in the software.                                                   |
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - |
| GPL - The GNU General Public License    http://www.gnu.org/licenses/gpl.txt |
| Permits anyone the right to use and modify the software without limitations |
| as long as proper  credits are given  and the original  and modified source |
| code are included. Requires  that the final product, software derivate from |
| the original  source or any  software  utilizing a GPL  component, such  as |
| this, is also licensed under the GPL license.                               |
|                                                                             |
| $Id$
\----------------------------------------------------------------------------*/

function CollapseReleases() {

	// ----------------------------------------------------------------------------
	// register class/global id
	// ----------------------------------------------------------------------------
	this.CN = "CollapseReleases";
	this.GID = "collapsereleases";
	mb.log.enter(this.CN, "__constructor");

	// ----------------------------------------------------------------------------
	// member variables
	// ----------------------------------------------------------------------------
	this.imgplus = new Image();
	this.imgplus.src = "/images/es/maximize.gif";
	this.imgminus = new Image();
	this.imgminus.src = "/images/es/minimize.gif";

	// ----------------------------------------------------------------------------
	// member functions
	// ----------------------------------------------------------------------------

	/**
	 * Go through all the releases of the current page
	 * and add the toggle icons. This functionality can
	 * be defined in the page tree using the two
	 * hidden fields:
	 *
	 * ~userpreference::JSCollapse (0|1)
	 * ~userpreference::JSCollapseToggleIcon (0|1)
	 *
	 */
	this.setupReleases = function() {
		mb.log.enter(this.CN, "setupReleases");
		var obj,list = mb.ui.getByTag("table");

		var defaultcollapse = true;
		if ((obj = mb.ui.get("userpreference::JSCollapse")) != null) {
			defaultcollapse = !(obj.value == 0);
		}

		var showtoggleicon = true;
		if ((obj = mb.ui.get("userpreference::JSCollapseToggleIcon")) != null) {
			showtoggleicon = !(obj.value == 0);
		}
		for (var i=0;i<list.length; i++) {
			var t = list[i];
			var id = (t.id || "");
			if (id.match(/tracks::\d+/i)) {

				// go through all the TR's of the table
				var defaultdisplay = (defaultcollapse ? "none" : "");
				var defaultimage =  (defaultcollapse ? "maximize" : "minimize");

				var rows = mb.ui.getByTag("tr", t);
				for (var j=0;j<rows.length; j++) {
					if (rows[j].className.match(/track|discid/i)) {
						rows[j].style.display = defaultdisplay;
					}
				}
				if ((obj = mb.ui.get(id.replace("tracks", "releaselinks"))) != null) {
					obj.style.display = defaultdisplay;
				}
				if ((obj = mb.ui.get(id.replace("tracks", "releaseevents"))) != null) {
					obj.style.display = defaultdisplay;
				}

				var elid = id.replace("tracks", "link");
				var el;
				if ((el = mb.ui.get(elid)) != null) {
					var td = el.parentNode;

					if (showtoggleicon) {

						// create the toggle icon, and the link wrapping
						// it. If the we register a click on it, we
						// have to stop propagation to the TD, else
						// the release will be toggled to the closed
						// state again if it was closed before.
						//
						// -- see: http://www.quirksmode.org/js/events_order.html
						var toggletd = td.previousSibling;
						while (toggletd != null && toggletd.tagName != "TD") {
							toggletd = toggletd.previousSibling;
						}

						var a = document.createElement("a");
						a.href = "javascript:; // Toggle release";
						a.id = id.replace("tracks", "expand");
						a.onfocus = function onfocus(event) { this.blur(); };
						a.onclick = function onclick(event) {
							try {
								if (window.event) {
									window.event.cancelBubble = true;
								} else if (event.stopPropagation) {
									event.stopPropagation();
								}
							} catch (e) {
								mb.log.error("Could not cancel propagation: $", e);
							}
							var id = this.id.replace("expand", "tracks");
							collapsereleases.showRelease(id);
							return false;
						};
						var img = document.createElement("img");

						img.src = "/images/es/"+defaultimage+".gif";
						img.alt = "Toggle release";
						img.border = 0;
						a.appendChild(img);
						toggletd.appendChild(a);

						// updated for opera, such that the cells display as they
						// are supposed to.
						toggletd.style.display = "";
						toggletd.style.width = "10px";
						td.style.width = "100%";
					}

					td.title = "Click the arrow icon to expand/collapse the release.";

					/*

					// attach method to open the release if the
					// mouse is hovered over the orange/yellow bar.
					td.style.cursor = "pointer";
					td.id = id.replace("tracks", "title");

					td.onclick = function onclick(event) {
						var id = this.id.replace("title", "tracks");

						// clear default hovering behaviour
						// after first click, else it is possibly
						// confusing that the release gets opened/closed
						// again.
						collapsereleases.clearHoverTimeout(id);
						this.onmouseover = null;
						this.onmouseout = null;
						this.title = "";

						collapsereleases.showRelease(id);
						return true;
					};
					*/

					/*
					td.onmouseover = function onmouseover(event) {
						var id = this.id.replace("title", "tracks");
						collapsereleases.setHoverTimeout(id);
					};
					td.onmouseout = function onmouseout(event) {
						var id = this.id.replace("title", "tracks");
						collapsereleases.clearHoverTimeout(id);
					};

					*/

					// we need to cancel event propagation on the
					// ReleaseTitle link, too. just return true, such
					// that the link click is not cancelled.
					el.onclick = function onclick(event) {
						try {
							if (window.event) {
								window.event.cancelBubble = true;
							} else if (event.stopPropagation) {
								event.stopPropagation();
							}
						} catch (e) {
							mb.log.error("Could not cancel propagation: $", e);
						}
						return true;
					};

				} else {
					mb.log.debug("Element $ not found", elid);
				}
			}
		}
		mb.log.exit();
	};

	/**
	 * Register a hover timeout for opening a release
	 *
	 * @param id	the id of the release
	 */
	this.setHoverTimeout = function(id) {
		if (this.timeouts == null) {
			this.timeouts = [];
		}
		var func = "collapsereleases.showRelease('"+id+"', true)";
		this.timeouts[id] = setTimeout(func, 800);
	};

	/**
	 * Un-Register a hover timeout for opening a release
	 *
	 * @param id	the id of the release
	 */
	this.clearHoverTimeout = function(id) {
		if (this.timeouts == null) {
			this.timeouts = [];
		}
		var ref = this.timeouts[id];
		clearTimeout(ref);
		this.timeouts[id] = null;
	};

	/**
	 * Go through all the releases of the current page
	 * and set their toggle status to the flag.
	 *
	 * @param flag	the new state (true|false)
	 */
	this.toggleAll = function(flag) {
		mb.log.enter(this.CN, "toggleAll");
		var list = mb.ui.getByTag("table");
		for (var i=0;i<list.length; i++) {
			var t = list[i];
			var id = (t.id || "");
			if (id.match(/tracks::\d+/i)) {
				this.showRelease(id, flag);
			}
		}
	};


	/**
	 * Set the new toggle status of the release with id
	 *
	 * @param id	the release id
	 * @param flag	the new state (true|false)
	 */
	this.showRelease = function(id, flag) {
		mb.log.enter(this.CN, "showRelease");
		var obj, img, t;

		// get reference to image object.
		if ((obj = mb.ui.get(id.replace("tracks", "expand"))) != null) {
			img = obj.firstChild;

			if (flag == null) {
				flag = img.src.match("maximize");
			}
			img.src = flag ? this.imgminus.src : this.imgplus.src;
			var display = flag ? "" : "none";

			if ((obj = mb.ui.get(id.replace("tracks", "releaselinks"))) != null) {
				obj.style.display = display;
			}
			if ((obj = mb.ui.get(id.replace("tracks", "releaseevents"))) != null) {
				obj.style.display = display;
			}
			if ((t = mb.ui.get(id)) != null) {
				var rows = mb.ui.getByTag("tr", t);
				for (var j=0;j<rows.length; j++) {
					if (rows[j].className.match(/track|discid/i)) {
						rows[j].style.display = display;
					}
				}
			} else {
				mb.log.debug("Element $ not found", tid);
			}
		} else {
			mb.log.error("el is null");
		}
		mb.log.exit();
	};


	/**
	 * This function replaces the non-javascript variant of the
	 * batchop selection with the checkboxes for the BatchOp form.
	 * The visible fields of the batchop form are added during
	 * this function as well.
	 */
	this.setupReleaseBatch = function() {
		mb.log.enter(this.CN, "setupReleaseBatch");
		var obj,list = mb.ui.getByTag("table");
		for (var i=0;i<list.length; i++) {
			var t = list[i];
			var id = (t.id || "");
			if (id.match(/tracks::\d+/i)) {

				var tagchecked = false;
				if ((obj = mb.ui.get(id.replace("tracks", "tagchecked"))) != null) {
					tagchecked = (obj.value == 1);
				}
				if ((obj = mb.ui.get(id.replace("tracks", "batchop"))) != null) {
					var releaseid = id.replace("tracks::", "");

					var input = document.createElement("input");
					input.id = id.replace("tracks", "batchcheckbox");
					input.type = "checkbox";
					input.onclick = function onclick(event) {
						var releaseid = this.id.replace("batchcheckbox::", "");
						var fieldName = "releaseid"+releaseid;
						var batchOpForm, obj;
						if ((batchOpForm = mb.ui.get("BatchOp")) != null)  {
							if (batchOpForm[fieldName] != null)  {
								var value = batchOpForm[fieldName].value;
								batchOpForm[fieldName].value = (value == "off" ? "on" : "off");
							}
						}
					};
					obj.innerHTML = "";
					obj.appendChild(input);
					input.checked = tagchecked;
					input.title = tagchecked ?
						"Deactivate this checkbox and click Update to unselect this release from the Batch Operations," :
						"Activate this checkbox and click Update to select this release for Batch Operations.";
				}
			}
		}

		// get BatchOp form, then container element (div)
		// inside it, to add user interface.
		if ((obj = mb.ui.get("BatchOp")) != null) {
			if ((obj = mb.ui.getByTag("div", obj)[0]) != null) {

				// used in /edit/albumbatch/done.html
				if (obj.id == "batchop::removereleases") {
					var el = document.createElement("input");
					el.type = "submit";
					el.name = "submit";
					el.value = "Update";
					obj.appendChild(el);

				// used in /show/artist/ and /show/release/?
				} else if (obj.id == "batchop::selectreleases") {

					var el = document.createElement("input");
					el.type = "image";
					el.alt = "Batch Edit";
					el.title = "Edit selected release(s) in a batch edit";
					el.src = "/images/batch.gif";
					obj.appendChild(el);
					el.style.border = "0";
					el.style.height = "13px";
					el.style.width = "13px";

					el = document.createElement("a");
					el.href = "#";
					el.title = "Edit selected release(s) in a batch edit";
					el.onclick = function onclick(event) {
						document.forms.BatchOp.submit();
						return false;
					};
					obj.appendChild(el);
					el.innerText = "Batch Operation";
					el.style.marginLeft = "5px";
				}
			}
		}
	};

	// exit constructor
	mb.log.exit();
}


// register class...
var collapsereleases = new CollapseReleases();
mb.registerDOMReadyAction(
	new MbEventAction(collapsereleases.GID, "setupReleases", "Setting up release toggle functions")
);
mb.registerDOMReadyAction(
	new MbEventAction(collapsereleases.GID, "setupReleaseBatch", "Setup release batch operations")
);

