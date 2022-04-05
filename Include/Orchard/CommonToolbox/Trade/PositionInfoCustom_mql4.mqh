/*

	PositionInfoCustom_mql4.mqh
	Copyright 2021, Orchard Forex 
	https://orchardforex.com 

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://orchardforex.com"
#property version   "1.00"
#property strict

int	CPositionInfoCustom::Count(string symbol, long magic) {
	int	result	=	0;
	int	count		=	OrdersTotal();
	for (int i=count-1; i>=0; i--) {
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
		if (OrderType()!=ORDER_TYPE_BUY && OrderType()!=ORDER_TYPE_SELL) continue;
		if (OrderSymbol()==symbol && OrderMagicNumber()==magic) result++;
	}
	return(result);
}

