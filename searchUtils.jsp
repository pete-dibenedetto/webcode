<%@ page import="java.util.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.math.*" %>
<%@ page import="com.autonomy.aci.*" %>
<%@ page import="com.autonomy.aci.services.*" %>
<%@ page import="com.autonomy.aci.businessobjects.*" %>
<%@ page import="com.autonomy.aci.constants.*" %>
<%@ page import="com.autonomy.aci.exceptions.*" %>
<%@ page import="com.autonomy.utilities.*" %>
<%@ page import="com.autonomy.client.*" %>
<%@ page import="com.autonomy.APSL.*"%>
<%@ page import="com.autonomy.aci.services.IDOLService"%>
<%@ page import="com.autonomy.aci.services.UserFunctionality"%>
<%@ page import="com.autonomy.aci.services.ChannelsFunctionality"%>
<%!

	String host = "127.0.0.1";
	int port = 9000;

	int iMaxResults = 10;  // get the top 10 hits

	AciConnectionDetails aciConnDetails = getConnDetails(host, port);


	public String generateParametricCategories(String sParaFieldName, String sSelectedParaValue)
	{
		StringBuffer sbParaCats = new StringBuffer();

		AciResponse aTagValues = getParametricFieldValues(sParaFieldName);

		if (aTagValues.checkForSuccess())
		{

			try
			{
				AciResponse aField = aTagValues.findFirstOccurrence("autn:field");

				AciResponse aFieldValue = aField.findFirstEnclosedOccurrence("autn:value");
				while (aFieldValue != null)
				{
				  if (aFieldValue.getName().equals("autn:value")) {

					String sNumCatDocs = "0";
					String sValue = "field value";

					if (aFieldValue != null) {
						sValue = aFieldValue.getValue();
						sNumCatDocs = getCatDocHits(sParaFieldName,sValue);

						if (sValue.equals(sSelectedParaValue)) {
							sbParaCats.append("<span class=\"selectedCatName\">&gt;&gt;&nbsp;" + sValue + "</span> <i style=\"font-size: 11px;; color: navy; \"><b>(" + sNumCatDocs + ")</b></i><br/>");
						} else {
							sbParaCats.append("<a href=\"javascript:submitCatRefinement('" + sParaFieldName + "','" + sValue + "');\" class=\"aYellowBold\">&gt;&nbsp;" + sValue + "</a> <i style=\"font-size: 11px;; color: #000000; \"><b>(" + sNumCatDocs + ")</b></i><br/>");
						}
					}

				  }
				  aFieldValue = aFieldValue.next();
				}

			} catch (Exception aciErr) {
				sbParaCats.append("Error: " + aciErr.toString());
			}

		} else {
			return "No tag values found.";
		}

		return sbParaCats.toString();
	}


	public AciResponse getParametricFieldValues(String sParaFieldName)
	{
		AciResponse acir = new AciResponse();

		AciAction aciAction = new AciAction("GetTagValues&FieldName=" + sParaFieldName + "&OutputEncoding=UTF8&Sort=Alphabetical");
		acir = submitAciAction(aciAction,aciConnDetails);
		return acir;
	}


	public String getCatDocHits(String sParaFieldName, String sValue)
	{
		String sCatDocHits = "0";

		AciResponse aQuickDocCount = new AciResponse();

		AciAction aciAction = new AciAction("Query&print=noresults&totalresults=true&predict=false&maxresults=1&FieldText=MATCH{" + sValue + "}:" + sParaFieldName);
		aQuickDocCount = submitAciAction(aciAction,aciConnDetails);


		if (aQuickDocCount.checkForSuccess())
		{

			try
			{
				AciResponse aNumHits = aQuickDocCount.findFirstOccurrence("autn:totalhits");

				if (aNumHits != null) {
					sCatDocHits = aNumHits.getValue();
				}

			} catch (Exception aciErr) {
				sCatDocHits = "Error: " + aciErr.toString();
			}

		}

		return sCatDocHits;
	}


	public String generateParametricSelectFormElement(String sQueryText, String sParaFieldName, String sSelCategoryName, String sSelCountry, String sSelCompanyName)
	{
		StringBuffer sbParaSelect = new StringBuffer();


		String sSelectedParaValue = "";
		if (sParaFieldName.equals("CompanyName")) {
			sSelectedParaValue = sSelCompanyName;
		} else if (sParaFieldName.equals("CategoryName")) {
			sSelectedParaValue = sSelCategoryName;
		} else if (sParaFieldName.equals("Country")) {
			sSelectedParaValue = sSelCountry;
		}

		String sFieldText = getFieldTextString(sSelCategoryName,sSelCountry,sSelCompanyName);


		AciResponse aTagValues = getParametricQueryFieldValues(sParaFieldName,sQueryText,sFieldText);

		if (aTagValues.checkForSuccess())
		{

			try
			{
				AciResponse aField = aTagValues.findFirstOccurrence("autn:field");

				String sNumValues = "0";
				AciResponse aFieldHits = aField.findFirstOccurrence("autn:number_of_values");
				if (aFieldHits != null) {
					sNumValues = aFieldHits.getValue();
				}

				sbParaSelect.append("<select class=\"paraSelectBox\" name=\"" + sParaFieldName + "\" id=\"" + sParaFieldName + "\" onChange=\"selectParametricRefinement(this,'sel" + sParaFieldName + "');\">");

				AciResponse aFieldValue = aField.findFirstEnclosedOccurrence("autn:value");
				while (aFieldValue != null)
				{
				  if (aFieldValue.getName().equals("autn:value")) {

					String sValue = "field value";
					if (aFieldValue != null) {
						sValue = aFieldValue.getValue();
					}
					String sSelOpt = "";
					if (sValue.equals(sSelectedParaValue)) {
						sSelOpt = " selected=\"selected\"";
					}
					sbParaSelect.append("<option value=\"" + URLEncoder.encode(sValue) + "\"" + sSelOpt + ">" + sValue + "</option>");

				  }
				  aFieldValue = aFieldValue.next();
				}

				sbParaSelect.append("<option value=\"\">RESET SELECTION</option></select> <i><b>(" + sNumValues + ")</b></i>");

			} catch (Exception aciErr) {
				sbParaSelect.append("Error: " + aciErr.toString());
			}

		} else {
			return "No tag values found.";
		}

		return sbParaSelect.toString();
	}

	public AciResponse getParametricQueryFieldValues(String sParaFieldName, String sQueryText, String sFieldText)
	{
		AciResponse acir = new AciResponse();

		AciAction aciAction = new AciAction("GetQueryTagValues&FieldName=" + sParaFieldName + "&OutputEncoding=UTF8&Sort=Alphabetical&text=" + sQueryText + sFieldText);
		acir = submitAciAction(aciAction,aciConnDetails);
		return acir;
	}


	public String printSearchResults(String qText, String sDateFilter, String sSort, String sMaxResults, String sMinScore, String sSelCategoryName, String sSelCountry, String sSelCompanyName, String sSourceName)
	{
		if (qText == null) {
			return "Error: Query Text is null";
		}

		String sFieldText = getFieldTextString(sSelCategoryName,sSelCountry,sSelCompanyName);

		StringBuffer sbResults = new StringBuffer();

		String noResults = "<tr><td><div align=\"center\"><br/>&nbsp;&nbsp;Sorry! No results were found<br/>for your query:<br/> '<span style=\"color: #003366; font-weight: bold;\">" + qText + "</span>'<br/>&nbsp;</div></td></tr>";

		AciResponse aResults = getSearchResults(qText,sFieldText,sDateFilter,sSort,sMaxResults,sMinScore,sSourceName);

		if (aResults.checkForSuccess())
		{

			try
			{
				AciResponse aResult = aResults.findFirstOccurrence("autn:hit");

				String sTotalHits = "";
				AciResponse aTotalHits = aResults.findFirstOccurrence("autn:totalhits");
				if (aTotalHits != null) {
					sTotalHits = aTotalHits.getValue();
				}

				if (!sSelCategoryName.equals("")) {

					sbResults.append("<tr><td align=\"left\" style=\"font-size: 11pt; font-weight: bold; text-decoration: none; \"><a href=\"javascript:clearCatRefinement();\" class=\"aYellowBold\">Northwind&nbsp;Categories</a>&nbsp;&gt;&nbsp;<span class=\"selectedCatName\">" + sSelCategoryName + "</span><BR/>");
				}
				sbResults.append("<hr/></td></tr>");
				sbResults.append("&nbsp;&nbsp;<span class=\"label\" style=\"font-size: 10pt;\">Total Results Found:</span> <span class=\"numHits\">" + sTotalHits + "</span>");

				String sSpell = "";
				AciResponse aSpell = aResults.findFirstOccurrence("autn:spellingquery");
				if (aSpell != null) {
					sSpell = aSpell.getValue();
				}
				if (!sSpell.equals("")) {
					sbResults.append("<BR/>&nbsp;&nbsp;<span style=\"font-size: 11pt; font-weight: bold;\">Did You Mean?</span>&nbsp;&nbsp;<a href=\"javascript: submitSpellingQuery('" + sSpell + "');\" style=\"font-size: 12pt; color: blue; text-decoration: underline;\">" + sSpell + "</a>");
				}

				sbResults.append("<BR/>&nbsp;<BR/><hr/>");

				//sbResults.append("<div style=\"background-color: #E8E8E8;\">&nbsp;&nbsp;Refine your results further: <br/>&nbsp;&nbsp;<span class=\"label\">Supplier:&nbsp;</span>" + generateParametricSelectFormElement(qText,"CompanyName", sSelCategoryName,sSelCountry,sSelCompanyName) + "<br/>&nbsp;&nbsp;<span class=\"label\">Supplier Country:&nbsp;</span>" + generateParametricSelectFormElement(qText,"Country", sSelCategoryName,sSelCountry,sSelCompanyName) + "<BR/></div>");


				//sbResults.append("<hr/></td></tr>");
				sbResults.append("<tr><td style=\"line-height: 3px;\">&nbsp;</td></tr>");

				while (aResult != null)
				{
					String sProductRef = "Doc URL";
					String sProductTitle = "Doc Title";
					String sProductDesc = "Description";
					String sProductCategory = "Category";
					String sProductUnitPrice = "Unit Price";
					String sProductQtyPerUnit = "Quantity Per Unit";
					String sProductUnitsInStock = "Units In Stock";

					String sSupplierCompanyName = "Supplier Company Name";
					String sSupplierCountry = "Supplier Country";
					String sSupplierPhone = "Supplier Phone Number";

					String sLinks = "";
					//String sDocScore = "100.00";

					//AciResponse aDocScore = aResult.findFirstEnclosedOccurrence("autn:weight");
					//if (aDocScore != null) {
					//	sDocScore = aDocScore.getValue();
					//}
					AciResponse aDocRef = aResult.findFirstEnclosedOccurrence("DREREFERENCE");
					if (aDocRef != null) {
						sProductRef = aDocRef.getValue();
					}
					AciResponse aDocTitle = aResult.findFirstEnclosedOccurrence("DRETITLE");
					if (aDocTitle != null) {
						sProductTitle = aDocTitle.getValue();
					}
					AciResponse aDocDesc = aResult.findFirstEnclosedOccurrence("ProductDescription");
					if (aDocDesc != null) {
						sProductDesc = aDocDesc.getValue();
					}
					AciResponse aDocCat = aResult.findFirstEnclosedOccurrence("CategoryName");
					if (aDocCat != null) {
						sProductCategory = aDocCat.getValue();
					}
					AciResponse aLinks = aResult.findFirstEnclosedOccurrence("autn:links");
					if (aLinks != null) {
						sLinks = aLinks.getValue();
					}


					AciResponse aDocPrice = aResult.findFirstEnclosedOccurrence("UnitPrice");
					if (aDocPrice != null) {
						sProductUnitPrice = "$" + aDocPrice.getValue();
						if (sProductUnitPrice.indexOf(".") > -1) {
							sProductUnitPrice = sProductUnitPrice.substring(0,sProductUnitPrice.lastIndexOf(".") + 3);
						}
					}
					AciResponse aDocQty = aResult.findFirstEnclosedOccurrence("QuantityPerUnit");
					if (aDocQty != null) {
						sProductQtyPerUnit = aDocQty.getValue();
					}
					AciResponse aDocStock = aResult.findFirstEnclosedOccurrence("UnitsInStock");
					if (aDocStock != null) {
						sProductUnitsInStock = aDocStock.getValue();
					}
					AciResponse aDocCompany = aResult.findFirstEnclosedOccurrence("CompanyName");
					if (aDocCompany != null) {
						sSupplierCompanyName = aDocCompany.getValue();
					}

					AciResponse aDocCountry = aResult.findFirstEnclosedOccurrence("Country");
					if (aDocCountry != null) {
						sSupplierCountry = aDocCountry.getValue();
					}
					AciResponse aDocPhone = aResult.findFirstEnclosedOccurrence("Phone");
					if (aDocPhone != null) {
						sSupplierPhone = aDocPhone.getValue();
					}


					sbResults.append("<tr><td>&nbsp;<!-- span style=\"font-size: 9pt\">sDocScore%</span -->");
					//sbResults.append("&nbsp;<img src=\"images/mail_icon.gif\" border=\"0\"/>&nbsp;&nbsp;");
					sbResults.append("<a href=\"highlighted.jsp?url=" + URLEncoder.encode(sProductRef) + "&links=" + sLinks + "\" target=\"_blank\"><span class=\"titleStyle\">" + sProductTitle + "</span></a><BR/>");
					sbResults.append("<span class=\"label\">Category1:</span>&nbsp;<span class=\"metaStyle\">" + sProductCategory + "</span><BR/>");
					sbResults.append("<span class=\"label\">Description:</span>&nbsp;<span class=\"metaStyle\">" + sProductDesc + "</span><BR/>");
					sbResults.append("<span class=\"label\">Database:</span>&nbsp;<span class=\"metaStyle\">" + sSourceName + "</span><BR/>");

					//sbResults.append("<a href=\"highlighted.jsp?url=" + URLEncoder.encode(sDocRef) + "&links=" + sLinks + "\" target=\"_blank\" class=\"blueLink\">[Highlighted]</a>&nbsp;<BR/>");

					sbResults.append("&nbsp;</td></tr>");
					sbResults.append("<tr><td style=\"line-height: 3px;\">&nbsp;</td></tr>");
					aResult= aResult.next();
				}

			} catch (Exception aciErr) {
				sbResults.append("Error: " + aciErr.toString());
			}


		}


		String sResult = sbResults.toString();


		if ((sResult.equals("")) || (sResult.equals("<tr><td>&nbsp;</td></tr>"))) {
			sResult = noResults;
		}
		return sResult;
	}




	public AciResponse getSearchResults(String qText, String sFieldText, String sDateFilter, String sSort, String sMaxResults, String sMinScore, String sSourceName)
	{
		AciResponse acir = new AciResponse();

		// Set the query text along with any other common parameters here
		AciAction aciAction = new AciAction("Query&Text=" + qText + "&TotalResults=true&Predict=false&DatabaseMatch=" + sSourceName + "&Print=all&Spellcheck=true&OutputEncoding=UTF8" + sFieldText + sDateFilter + "&sort=" + sSort + "&maxresults=" + sMaxResults + "&minscore=" + sMinScore);
		acir = submitAciAction(aciAction,aciConnDetails);

		return acir;
	}


	public String getDateFilter(String svFromDateDay, String svFromDateMonth, String svFromDateYear, String svToDateDay, String svToDateMonth, String svToDateYear)
	{
		String sDateFilter = "";

		if ((!svFromDateDay.equals("")) && (!svFromDateMonth.equals("")) && (!svFromDateYear.equals(""))) {
			sDateFilter += "&MinDate=" + svFromDateDay + "/" + svFromDateMonth + "/" + svFromDateYear;
		}
		if ((!svToDateDay.equals("")) && (!svToDateMonth.equals("")) && (!svToDateYear.equals(""))) {
			sDateFilter += "&MaxDate=" + svToDateDay + "/" + svToDateMonth + "/" + svToDateYear;
		}

		return sDateFilter;
	}


	public String getFieldTextString(String sSelCategoryName, String sSelCountry, String sSelCompanyName)
	{
		String sFieldText = "";

		if (!sSelCategoryName.equals("")) {
			sFieldText += "MATCH{" + sSelCategoryName + "}:*/CategoryName";
		}
		if (!sSelCountry.equals("")) {
			if (!sFieldText.equals("")) {
				sFieldText += "+AND+";
			}
			sFieldText += "MATCH{" + sSelCountry + "}:*/Country";
		}
		if (!sSelCompanyName.equals("")) {
			if (!sFieldText.equals("")) {
				sFieldText += "+AND+";
			}
			sFieldText += "MATCH{" + sSelCompanyName + "}:*/CompanyName";
		}


		if (!sFieldText.equals("")) {
			sFieldText = "&fieldtext=" + sFieldText;
		}

		return sFieldText;
	}


// ******************** //
// * Base ACI Methods * //
// ******************** //

	public AciResponse submitAciAction(AciAction aciAction, AciConnectionDetails connDetails)
	{
		AciResponse acir = new AciResponse();
		try
		{
			AciConnection aciConn = new AciConnection();
			try {
				aciConn = new AciConnection(connDetails);
			} catch (java.io.UnsupportedEncodingException uee) {
				return acir;
			}
			acir = aciConn.aciActionExecute(aciAction);
		}
		catch(AciException exp)
		{
			return acir;
		}
		return acir;
	}


	public AciConnectionDetails getConnDetails(String sHost, int iPort)
	{
		AciConnectionDetails connDetails = new AciConnectionDetails();
		connDetails.setHost(sHost);
		connDetails.setPort(iPort);
		connDetails.setTimeout(150000);
		connDetails.setRetries(0);
		return connDetails;
	}

//  Old methods


	public AciResponse getFailedListResults(String sFailedDBName)
	{
		AciResponse acir = new AciResponse();

		// Set the query text along with any other common parameters here
		AciAction aciAction = new AciAction("Query&Text=*&TotalResults=true&Predict=false&Print=all&combine=simple&OutputEncoding=UTF8&databasematch=" + sFailedDBName + "&MaxResults=50000");
		acir = submitAciAction(aciAction,aciConnDetails);
		return acir;
	}



// Supporting methods //


	public String trimSpace(String inStr)
	{
		String outStr = "";
		inStr = switchChars(inStr, "  ", " ");
		StringTokenizer st = new StringTokenizer(inStr);
		while (st.hasMoreTokens()) {
		  String tmp = st.nextToken();
		  outStr += tmp;
		  if (st.hasMoreTokens()) {
		    outStr += " ";
		  }
		}
		return outStr;
	}


   	public static final String switchChars(String s, String seq, String equiv)
   	{
      String str = seq;
      if ((s.indexOf(str) > -1) && (str != null)) {
	    while (s.indexOf(str) > -1) {
	      String s1 = s.substring(0,s.indexOf(str)) + equiv + s.substring(s.indexOf(str) + str.length());
	      s = s1;
	    }
	  }
   	  return s;
   	}


	public String getDocTypeImage(String reference)
	{
		String docTypeImage = "webdoc_icon.gif";
		if(reference != null)
		{
			int index = reference.lastIndexOf(".");
		    String docType = "";
			if(index > 0 && index+4 <= reference.length())
			{
				docType = reference.substring(index + 1, index + 4);
				if(docType.equalsIgnoreCase("pdf"))
				{
					//doc type is pdf
					docTypeImage = "pdf_icon.gif";
				}
				else if (docType.equalsIgnoreCase("doc"))
				{
					//doc type is word
					docTypeImage = "word_icon.gif";
				}
				else if (docType.equalsIgnoreCase("htm"))
				{
					//doc type is web
					docTypeImage = "webdoc_icon.gif";
				}
				else if (docType.equalsIgnoreCase("ppt"))
				{
					//doc type is powerpoint
					docTypeImage = "ppt_icon.gif";
				}
				else if (docType.equalsIgnoreCase("txt"))
				{
					//doc type is text
					docTypeImage = "txt_icon.gif";
				}
				else if (docType.equalsIgnoreCase("zip"))
				{
					//doc type is zip
					docTypeImage = "zip_icon.gif";
				}

			}
		}
		return docTypeImage;
	}

//Pete' Code for running clusters against WHSOURCE
//March 01, 2007

public String printClusterResults()
	{

		StringBuffer sbClusterResults = new StringBuffer();
		//StringBuffer sbClusterNewsResults = new StringBuffer();

		String noResults2 = "<tr><td><div align=\"center\"><br/>&nbsp;&nbsp;Sorry! No clusters were present</div></td></tr>";

		AciResponse aResults2 = getCluster();

		if (aResults2.checkForSuccess())
		{

			try
			{
				AciResponse aResult2 = aResults2.findFirstOccurrence("autn:hit");

				String sTotalHits2 = "";
				AciResponse aTotalHits2 = aResults2.findFirstOccurrence("autn:numhits");
				if (aTotalHits2 != null) {
					sTotalHits2 = aTotalHits2.getValue();
				}

				//sbClusterResults.append("&nbsp;&nbsp;<span class=\"label\" style=\"font-size: 10pt;\">Total Results Found:</span> <span class=\"numHits\">" + sTotalHits2 + "</span>");
				int iCounter = 0;


				while (aResult2 != null)
				{
					String sNewsURL = "Doc URL";
					String sNewsTitle = "Doc Title";
					String sNewsDesc = "Description";
					String sClusterId = "Cluster #";
					String sClusterName = "Cluster Name";
					String sDocId = "Document Id";
					String sWHSource = "Database Name";

					String sNewsDocId = "Document Id";

					String sNewsLinks = "";
					//String sDocScore = "100.00";

					//AciResponse aDocScore = aResult.findFirstEnclosedOccurrence("autn:weight");
					//if (aDocScore != null) {
					//	sDocScore = aDocScore.getValue();
					//}
					AciResponse aDocRef2 = aResult2.findFirstEnclosedOccurrence("DREREFERENCE");
					if (aDocRef2 != null) {
						sNewsURL = aDocRef2.getValue();
					}
					AciResponse aDocTitle2 = aResult2.findFirstEnclosedOccurrence("DRETITLE");
					if (aDocTitle2 != null) {
						sNewsTitle = aDocTitle2.getValue();
					}
					AciResponse aDocDesc2 = aResult2.findFirstEnclosedOccurrence("DRECONTENT");
					if (aDocDesc2 != null) {
						sNewsDesc = aDocDesc2.getValue();
					}

					AciResponse aLinks2 = aResult2.findFirstEnclosedOccurrence("autn:links");
					if (aLinks2 != null) {
						sNewsLinks = aLinks2.getValue();
					}

					AciResponse aClusterId = aResult2.findFirstEnclosedOccurrence("autn:cluster");
					if (aClusterId != null) {
						sClusterId = aClusterId.getValue();
					}

					AciResponse aClusterDocId = aResult2.findFirstEnclosedOccurrence("autn:id");
					if (aClusterDocId != null) {
						sDocId = aClusterDocId.getValue();
					}
					AciResponse aWHSourceId = aResult2.findFirstEnclosedOccurrence("DREDBNAME");
					if (aWHSourceId != null) {
						sWHSource = aWHSourceId.getValue();
					}
					sbClusterResults.append("<tr>");
					sbClusterResults.append("<td width=\"38%\" align=\"justify\" valign=\"top\">");
					//sbResults.append("&nbsp;<img src=\"images/mail_icon.gif\" border=\"0\"/>&nbsp;&nbsp;");
					sbClusterResults.append("&nbsp;<!-- span style=\"font-size: 9pt\">sDocScore%</span -->");
					sbClusterResults.append("<a href=\"highlighted.jsp?url=" + URLEncoder.encode(sNewsURL) + "&links=" + sNewsLinks + "\" target=\"_blank\"><span class=\"titleStyle\">" + sNewsTitle + "</span></a><BR/>");
					sbClusterResults.append("<span class=\"label\">Description:</span>&nbsp;<span class=\"metaStyle\">" + sNewsDesc + "</span><BR/>");
					//sbClusterResults.append("<span class=\"label\">Document ID:</span>&nbsp;<span class=\"metaStyle\">" + sDocId + "</span><BR/>");
					sbClusterResults.append("<span class=\"label\">Database:</span>&nbsp;<span class=\"metaStyle\">" + sWHSource + "</span><BR/>");



					//Call to get News Articles
					AciResponse aResultsNewsArticles = printNewsResults(sDocId);

					if (aResultsNewsArticles.checkForSuccess())
					{

					try
					{
					AciResponse aResultNews = aResultsNewsArticles.findFirstOccurrence("autn:hit");

					String sNewsVar = "newsOpts";
					//int Counter = 0;
					sNewsVar = sNewsVar + iCounter;
					//sbClusterResults.append(sNewsVar);
					String sTotalNewsHits2 = "";
					AciResponse aTotalNewsHits2 = aResultsNewsArticles.findFirstOccurrence("autn:numhits");

					if (aTotalNewsHits2 != null) {
						sTotalNewsHits2 = aTotalNewsHits2.getValue();
					}
					sbClusterResults.append("</td>");
					sbClusterResults.append("&nbsp;&nbsp;<td align=\"justify\" valign=\"top\">");
					sbClusterResults.append("<span id=\"newsLabel\" name=\"newsLabel\" onclick=\"showHideNewsOpts(" +sNewsVar+");\" title=\"Show News Articles\" class=\"axnLabel\" onMouseOver=\"this.className='axnLabelOn';return true;\" onMouseOut=\"this.className='axnLabel';return true;\">&gt;&gt; Show News Articles</span>&nbsp");
					//sbClusterResults.append("<div id=newsOpts style=\"display: none\">");
					sbClusterResults.append("<div id="+sNewsVar +" style=\"display: none\">");

				while (aResultNews != null)
				{
					String sNewsArticleURL = "Doc URL";
					String sNewsArticleTitle = "Doc Title";
					String sNewsArticleDesc = "SUMMARY";
					String sNewsSource = "Database";

					String sNewsLinks2 = "";
					String sTitle ="";


					//String sDocScore = "100.00";

					//AciResponse aDocScore = aResult.findFirstEnclosedOccurrence("autn:weight");
					//if (aDocScore != null) {
					//	sDocScore = aDocScore.getValue();
					//}
					AciResponse aDocNewsRef2 = aResultNews.findFirstEnclosedOccurrence("DREREFERENCE");
					if (aDocNewsRef2 != null) {
						sNewsArticleURL = aDocNewsRef2.getValue();
					}
					AciResponse aDocNewsTitle2 = aResultNews.findFirstEnclosedOccurrence("DRETITLE");
					if (aDocNewsTitle2 != null) {
						sNewsArticleTitle = aDocNewsTitle2.getValue();
					}
					AciResponse aDocNewsDesc2 = aResultNews.findFirstEnclosedOccurrence("SUMMARY"); //changed from DRECONTENT to Summary to shorten display length 3/19
					if (aDocNewsDesc2 != null) {
						sNewsArticleDesc = aDocNewsDesc2.getValue();
					}

					AciResponse aNewsLinks2 = aResultNews.findFirstEnclosedOccurrence("autn:links");
					if (aNewsLinks2 != null) {
						sNewsLinks2 = aNewsLinks2.getValue();
					}


					AciResponse aNewsDocId = aResultNews.findFirstEnclosedOccurrence("autn:id");
					if (aNewsDocId != null) {
						sNewsDocId = aNewsDocId.getValue();
					}

										
					AciResponse aNewsSourceId = aResultNews.findFirstEnclosedOccurrence("DREDBNAME");
					if (aNewsSourceId != null) {
						sNewsSource = aNewsSourceId.getValue();
					}

					//sbClusterResults.append("<input type=\"checkbox\" id =\"article"+iCounter+"\" name=\"article"+iCounter+"\" align=\"middle\">");

					sbClusterResults.append("<a href=\"highlighted.jsp?url=" + URLEncoder.encode(sNewsArticleURL) + "&links=" + sNewsLinks2 + "\" target=\"_blank\"><span class=\"titleStyle\">" + sNewsArticleTitle + "</span></a><BR/>");
					sbClusterResults.append("<span class=\"label\">Description:</span>&nbsp;<span class=\"metaStyle\">" + sNewsArticleDesc + "</span><BR/>");
					sbClusterResults.append("<span class=\"label\">Document ID:</span>&nbsp;<span class=\"metaStyle\">" + sNewsDocId + "</span><BR/>");
					sbClusterResults.append("<span class=\"label\">URL:</span>&nbsp;<span class=\"metaStyle\">" + sNewsArticleURL + "</span><BR/>");
					sbClusterResults.append("<span class=\"label\">Database:</span>&nbsp;<span class=\"metaStyle\">" + sNewsSource + "</span><BR/>");

					//iNewsArticle = iNewsArticle+1; //increment checkbox identifier
					aResultNews= aResultNews.next();
					}

					} catch (Exception aciErr) {
						sbClusterResults.append("Error: " + aciErr.toString());
					}


					}

					sbClusterResults.append("</div>");
					sbClusterResults.append("</td>");
					sbClusterResults.append("<td valign=\"top\" align=\"center\">");
					sbClusterResults.append("<a class=\"textButton\" href=\"http://localhost:9000/action=AgentAdd&UserName=admin&AgentName=CFE+Treaty&PositiveDocs=115462\" title=\"Create Agent\" target=\"_self\">Agent");
					//sbClusterResults.append("<input type=\"button\" name=\"Agent\" value=\"Create An Agent\">");
					sbClusterResults.append("</td>");
					sbClusterResults.append("<td valign=\"top\" align=\"center\">");
					//sbClusterResults.append("<input type=\"checkbox\" id=\"Feed\" onclick=\"checkAll("+iCounter+")\";\"name=\"Feed\" value=\"MorningFeed\" >");
					sbClusterResults.append("<input type=\"checkbox\" name=\"source"+iCounter+"\" id=\"source"+iCounter+"\" value="+sDocId+">");

					//sbClusterResults.append(iCounter);
					sbClusterResults.append("</tr>");

					iCounter = iCounter+1;

					aResult2= aResult2.next();
				}

			} catch (Exception aciErr) {
				sbClusterResults.append("Error: " + aciErr.toString());
			}


		}

		String sResult2 = sbClusterResults.toString();

		if ((sResult2.equals("")) || (sResult2.equals("<tr><td>&nbsp;</td></tr>"))) {
			sResult2 = noResults2;
		}
		return sResult2;
	}


	public AciResponse getCluster()
	{
		AciResponse acir2 = new AciResponse();

		// Set the query text along with any other common parameters here
		AciAction aciAction2 = new AciAction("Query&Text=*&databasematch=WHSource&print=all&maxresults=100");
		acir2 = submitAciAction(aciAction2,aciConnDetails);
		return acir2;
	}

	public AciResponse printNewsResults(String sDocId)
	{
		AciResponse acirNews = new AciResponse();

		// Set the query text along with any other common parameters here
		AciAction aciActionNews = new AciAction("Suggest&ID="+sDocId+"&databasematch=NewsSources&print=all&maxresults=5&QuerySummary=true");
		acirNews = submitAciAction(aciActionNews,aciConnDetails);
		return acirNews;
	}

//END of Pete's Custom Code March 01,2007

%>
