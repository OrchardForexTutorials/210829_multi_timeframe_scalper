/*
	TradeObserver.mqh

	Copyright 2021, Orchard Forex
	https://www.orchardforex.com

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://www.orchardforex.com"
#property version   "1.00"
#property strict


class CTradeObserver {

	//	Order functions
	//
 	//OrderClosePrice
 	//OrderCloseTime
 	//OrderComment
 	//OrderCommission
 	//OrderExpiration
 	//OrderLots
 	//OrderMagicNumber
 	//OrderOpenPrice
 	//OrderOpenTime
 	//OrderProfit
 	//OrderStopLoss
 	//OrderSwap
 	//OrderSymbol
 	//OrderTakeProfit
 	//OrderTicket
 	//OrderType

 typedef void (*TOnTradeHandler)();
 
 enum ENUM_ORDER_DATA {
 	order_ticket,
 	order_closeTime,
 	order_commission,
 	order_expiration,
 	order_lots,
 	order_magicNumber,
 	order_openPrice,
 	order_openTime,
 	order_stopLoss,
 	order_takeProfit,
 	order_type,

 	order_closePrice,
 	order_profit,
 	order_swap,
 	
 	order_last,
 	order_limit = order_type,
 };
 
 struct STradeObserverData {
 	int		count;
 	double	trades[][order_last];
 };

 private:
 
 protected:

	TOnTradeHandler		mHandler;
	STradeObserverData	mPreviousData;
	void	Fill(STradeObserverData &data);
	
 public:
	CTradeObserver(TOnTradeHandler handler);
	~CTradeObserver();

	void	StartScan();
	
};

CTradeObserver::CTradeObserver(TOnTradeHandler handler) {

	mHandler = handler;
	Fill(mPreviousData);
	
}

CTradeObserver::~CTradeObserver() {
}

void		CTradeObserver::StartScan(void) {

	STradeObserverData	currentData;
	Fill(currentData);
	bool	changed	= false;
	
	if ( currentData.count!=mPreviousData.count ) {
		changed	=	true;
	} else {
		for ( int i=0; !changed && i<currentData.count; i++ ) {
			for ( int j=0; !changed && j<=order_limit; j++ ) {		//	Only going as far as type, add or change in enum
				if (	currentData.trades[i][j] != mPreviousData.trades[i][j] ) {
					changed	=	true;
					break;
				}
			}
		}
	}

	mPreviousData	=	currentData;	
	if ( changed ) {
		mHandler();
	}
	
	return;
	
}

void		CTradeObserver::Fill(STradeObserverData &data) {

	data.count	=	OrdersTotal();
	ArrayResize(data.trades, data.count);
	if (data.count<1) return;
	for (int i=0; i<data.count; i++) {
		data.trades[i][order_ticket] = 0;
		if ( !OrderSelect(i, SELECT_BY_POS, MODE_TRADES) ) continue;
		data.trades[i][order_ticket]			=	OrderTicket();
		data.trades[i][order_closePrice]		=	OrderClosePrice();
		data.trades[i][order_closeTime]		=	(double)OrderCloseTime();
		data.trades[i][order_commission]		=	OrderCommission();
		data.trades[i][order_expiration]		=	(double)OrderExpiration();
		data.trades[i][order_lots]				=	OrderLots();
		data.trades[i][order_magicNumber]	=	OrderMagicNumber();
		data.trades[i][order_openPrice]		=	OrderOpenPrice();
		data.trades[i][order_openTime]		=	(double)OrderOpenTime();
		data.trades[i][order_profit]			=	OrderProfit();
		data.trades[i][order_stopLoss]		=	OrderStopLoss();
		data.trades[i][order_swap]				=	OrderSwap();
		data.trades[i][order_takeProfit]		=	OrderTakeProfit();
		data.trades[i][order_type]				=	OrderType();
	}
	ArraySort(data.trades);
	
	return;
	
}
	

