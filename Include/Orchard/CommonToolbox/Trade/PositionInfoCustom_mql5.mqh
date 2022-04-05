/*

	PositionInfoCustom_mql5.mqh
	Copyright 2021, Orchard Forex 
	https://orchardforex.com 

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://orchardforex.com"
#property version   "1.00"
#property strict

int	CPositionInfoCustom::Count(string symbol, long magic) {
	int	result	=	0;
	int	count		=	PositionsTotal();
	for (int i=count-1; i>=0; i--) {
		if (PositionGetTicket(i)<=0) continue;
		if (CPositionInfo::Symbol()==symbol && CPositionInfo::Magic()==magic) result++;
	}
	return(result);
}
