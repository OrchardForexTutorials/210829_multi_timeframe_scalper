/*

	TradeCustom.mqh
	Copyright 2021, Orchard Forex 
	https://orchardforex.com 

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://orchardforex.com"
#property version   "1.00"
#property strict

#include	"PositionInfoCustom.mqh"
#ifdef __MQL4__
	#include "Trade_mql4.mqh"
#endif
#ifdef __MQL5__
	#include <Trade/Trade.mqh>
#endif

class CTradeCustom : public CTrade {

};

