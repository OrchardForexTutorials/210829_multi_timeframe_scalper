/*

	PositionInfoCustom.mqh
	Copyright 2021, Orchard Forex 
	https://orchardforex.com 

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://orchardforex.com"
#property version   "1.00"
#property strict

#ifdef __MQL4__
	class CPositionInfo {};
#endif
#ifdef __MQL5__
	#include <Trade/PositionInfo.mqh>
#endif

class CPositionInfoCustom : public CPositionInfo {

public:

	int	Count(string symbol, long magic);

};

#ifdef __MQL4__
	#include "PositionInfoCustom_mql4.mqh"
#endif
#ifdef __MQL5__
	#include "PositionInfoCustom_mql5.mqh"
#endif


