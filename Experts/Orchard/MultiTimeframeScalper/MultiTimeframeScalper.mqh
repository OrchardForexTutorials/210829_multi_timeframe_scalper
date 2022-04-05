/*

	MultiTimeframeScalper.mq4
	Copyright 2021, Orchard Forex
	https://www.orchardforex.com

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://www.orchardforex.com"
#property version   "1.00"
#property strict

/*
	Trading Rules
	
	1.	Set trend direction using higher timeframe 8 and 21 ema
	
	2.	Match trend on current timeframe 8, 13, 21 ema
	
	3.	Trigger on price move back into 8 ema
	
	4.	Cancel trigger on price close past 21 ema
	
	5.	entry at hi/lo of trigger candle +/- 3 pips
	
	6.	sl at hi/lo of previous 5 bars +/- 3 pips
	
	7.	tp1 at 1:1 rr ratio
	
	8.	tp2 at 2:1 rr ratio or trailing stop at hi/lo previous 3 bars

*/

#include					<Orchard/CommonToolbox/Trade/TradeCustom.mqh>
CTradeCustom			Trade;
CPositionInfoCustom	PositionInfo;

struct STargetPrice {
	ENUM_ORDER_TYPE	type;
	double				entryPrice;
	double				sl;
	double				tp;
};


//	Some inputs
//	Moving average
input	ENUM_TIMEFRAMES		InpAnchorTimeframe				=	PERIOD_H1;		//	Anchor Timeframe

input	int						InpAnchorFastPeriod				=	8;				//	Anchor Fast MA Period
input	ENUM_MA_METHOD			InpAnchorFastMethod				=	MODE_EMA;		//	Anchor Fast MA Method
input	ENUM_APPLIED_PRICE	InpAnchorFastAppliedPrice		=	PRICE_CLOSE;	//	Anchor Fast MA Applied price

input	int						InpAnchorSlowPeriod				=	21;				//	Anchor Slow MA Period
input	ENUM_MA_METHOD			InpAnchorSlowMethod				=	MODE_EMA;		//	Anchor Slow MA Method
input	ENUM_APPLIED_PRICE	InpAnchorSlowAppliedPrice		=	PRICE_CLOSE;	//	Anchor Slow MA Applied price

//	Main 3 averages
input	int						InpMainFastPeriod					=	8;				//	Main Fast MA Period
input	ENUM_MA_METHOD			InpMainFastMethod					=	MODE_EMA;		//	Main Fast MA Method
input	ENUM_APPLIED_PRICE	InpMainFastAppliedPrice			=	PRICE_CLOSE;	//	Main Fast MA Applied price

input	int						InpMainMidPeriod					=	13;				//	Main Mid MA Period
input	ENUM_MA_METHOD			InpMainMidMethod					=	MODE_EMA;		//	Main Mid MA Method
input	ENUM_APPLIED_PRICE	InpMainMidAppliedPrice			=	PRICE_CLOSE;	//	Main Mid MA Applied price

input	int						InpMainSlowPeriod					=	21;				//	Main Slow MA Period
input	ENUM_MA_METHOD			InpMainSlowMethod					=	MODE_EMA;		//	Main Slow MA Method
input	ENUM_APPLIED_PRICE	InpMainSlowAppliedPrice			=	PRICE_CLOSE;	//	Main Slow MA Applied price

//	Input point High/Low of previous candles
input int						InpEntryLookback					=	5;					//	Entry price lookback
input	int						InpEntryOffsetPoints				=	30;				//	Entry price offset


//	For the tp/sl
input	double					InpRatio					=	1.25;				//	P/L ratio

//	General items
input	double					InpOrderSize			=	0.01;				//	Order size
input	int						InpMagicNumber			=	212121;			//	Magic number
input	string					InpTradeComment		=	__FILE__;		//	Trade comment

//	For inputs that need one time conversion
double	GEntryOffset;

// This is where I use the modular indicator classes
//	Include the indicator classes
#include <Orchard/CommonToolbox/Indicators/IndicatorMA.mqh>
CIndicatorMA	MAAnchorFast;
CIndicatorMA	MAAnchorSlow;
CIndicatorMA	MAMainFast;
CIndicatorMA	MAMainMid;
CIndicatorMA	MAMainSlow;

STargetPrice	gTarget;

int OnInit() {

	if (PeriodSeconds(InpAnchorTimeframe)<=PeriodSeconds(Period())) {
		PrintFormat("You must select an anchor timeframe higher than the current chart. Current=%s, selected=%s", EnumToString((ENUM_TIMEFRAMES)Period()), EnumToString(InpAnchorTimeframe));
		return(INIT_PARAMETERS_INCORRECT);
	}

	//	For inputs that need one time conversion
	GEntryOffset	=	InpEntryOffsetPoints*SymbolInfoDouble(Symbol(), SYMBOL_POINT);
	
	//	Initialise the magic number in the Trade object
	Trade.SetExpertMagicNumber(InpMagicNumber);

	//	Initialise the indicators
	MAAnchorFast.Init(Symbol(), InpAnchorTimeframe, InpAnchorFastPeriod, InpAnchorFastMethod, InpAnchorFastAppliedPrice);
	MAAnchorSlow.Init(Symbol(), InpAnchorTimeframe, InpAnchorSlowPeriod, InpAnchorSlowMethod, InpAnchorSlowAppliedPrice);

	MAMainFast.Init(Symbol(), Period(), InpMainFastPeriod, InpMainFastMethod, InpMainFastAppliedPrice);
	MAMainMid.Init(Symbol(), Period(), InpMainMidPeriod, InpMainMidMethod, InpMainMidAppliedPrice);
	MAMainSlow.Init(Symbol(), Period(), InpMainSlowPeriod, InpMainSlowMethod, InpMainSlowAppliedPrice);

	NewBar();					//	Just sets up prev time to avoid trading when first opened
	
	gTarget.entryPrice		=	0;		//	No target

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

	//	Nothing to do here now, common toolbox took care of it
	
}

void OnTick() {

	//	Some general get out early conditions
	if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;	//	exit if expert trading is not allowed
	if (!MQLInfoInteger(MQL_TRADE_ALLOWED)) return;
	if (!AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) return;
	if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) return;
	
	if (!NewBar()) {
		OpenAtTarget();							//	If the trigger is already set test if target reached
		return;
	}
														//	Only trade once per bar
	if (PositionInfo.Count(Symbol(), InpMagicNumber)>0)	return;	//	Only trade if there are no current trades open
	
	if (!WaitForHTF(Symbol(), InpAnchorTimeframe))	return;			//	Anchor data not available
	
	//	First check the anchor direction
	double	anchorFast	=	MAAnchorFast.GetValue(1);
	double	anchorSlow	=	MAAnchorSlow.GetValue(1);
	double	anchorClose	=	iClose(Symbol(), InpAnchorTimeframe, 1);
	ENUM_ORDER_TYPE	anchorMode;
	
	//	Strategy calls for the price being to one side of the fast ma but isn't clear
	//		if this means whole candle or just close
	//	I'm only testing recent close.
	if (anchorFast>anchorSlow) {	//	Possible buying
		if (anchorClose<anchorFast)	return;	//	Not aligned
		anchorMode	=	ORDER_TYPE_BUY;
	} else {								//	possible selling
		if (anchorClose>anchorFast)	return;	//	Not aligned
		anchorMode	=	ORDER_TYPE_SELL;
	}
	
	//	Now is there a direction on the main chart and does it match the anchor
	//	This is where the strategy talks about the ma fanning out
	//	I've kept it simple to just being aligned
	double	mainFast		=	MAMainFast.GetValue(1);
	double	mainMid		=	MAMainMid.GetValue(1);
	double	mainSlow		=	MAMainSlow.GetValue(1);
	double	mainClose	=	iClose(Symbol(), Period(), 1);
	double	mainHi		=	iHigh(Symbol(), Period(), 1);
	double	mainLo		=	iLow(Symbol(), Period(), 1);
	
	//	I'm adding a confirmation that the ma are aligned with the anchor
	//	along with being aligned
	//	Check for a pullback to create a trigger
	//	Check for closing past slow ma for no go
	if (mainFast>mainMid && mainMid>mainSlow) {		//	buying

		if (anchorMode!=ORDER_TYPE_BUY)	return;		//	current tf doesn't agree with higher tf

		if (mainClose<=mainSlow) {							//	close past slow means cancel
			gTarget.entryPrice	=	0;
			return;
		}

		if (mainLo<=mainFast) {								//	Pullback to fast ma, not checking for existing trigger
		
			double entryPrice		=	iHigh(Symbol(), Period(), iHighest(Symbol(), Period(), MODE_HIGH, InpEntryLookback, 2));	//	2 from the example
			entryPrice				+=	GEntryOffset;
			double exitPrice		=	mainLo - GEntryOffset;	//	exit is offset from trigger bar
			double tpPrice			=	entryPrice + ((entryPrice-exitPrice)*InpRatio);	//	Only using a single target, strategy has 2 targets
			
			gTarget.entryPrice	=	entryPrice;
			gTarget.sl				=	exitPrice;
			gTarget.tp				=	tpPrice;
			gTarget.type			=	anchorMode;
			
		}
		
	} else
	if (mainFast<mainMid && mainMid<mainSlow) {		//	selling
	
		if (anchorMode!=ORDER_TYPE_SELL)	return;		//	another mismatch

		if (mainClose>=mainSlow) {							//	close past slow means cancel
			gTarget.entryPrice	=	0;
			return;
		}

		if (mainHi>=mainFast) {								//	Pullback to fast ma
		
			double entryPrice		=	iLow(Symbol(), Period(), iLowest(Symbol(), Period(), MODE_LOW, InpEntryLookback, 2));	//	2 from the example
			entryPrice				-=	GEntryOffset;
			double exitPrice		=	mainHi + GEntryOffset;	//	exit is offset from trigger bar
			double tpPrice			=	entryPrice + ((entryPrice-exitPrice)*InpRatio);;	//	Only using a single target, strategy has 2 targets
			
			gTarget.entryPrice	=	entryPrice;
			gTarget.sl				=	exitPrice;
			gTarget.tp				=	tpPrice;
			gTarget.type			=	anchorMode;
			
		}

	} else {													//	Not aligned so just get out
		//	This case not mentioned in the strategy
	}

	//	Just in case a new target is set and already at entry point
	OpenAtTarget();	
	
}

void	OpenAtTarget() {

	if (gTarget.entryPrice==0)	return;	//	no target set
	
	if (gTarget.type==ORDER_TYPE_BUY) {
		if (SymbolAsk()>=gTarget.entryPrice) {
			OpenTrade();
			gTarget.entryPrice	=	0;		//	reset
		}
	} else {
		if (SymbolBid()<=gTarget.entryPrice) {
			OpenTrade();
			gTarget.entryPrice	=	0;		//	reset
		}
	}
	
}

void	OpenTrade() {

	//	Opens trade based on gTarget
	if (gTarget.entryPrice==0)	return;
	
	//	It isn't necessary to pull these out, I just think it's easier to read
	ENUM_ORDER_TYPE	type	=	gTarget.type;
	double				price	=	NormalizeDouble(gTarget.entryPrice, Digits());
	double				sl		=	NormalizeDouble(gTarget.sl,			Digits());
	double				tp		=	NormalizeDouble(gTarget.tp,			Digits());
	
	if (!Trade.PositionOpen(Symbol(), type, InpOrderSize, price, sl, tp, InpTradeComment)) {
		PrintFormat("Error %i placing order type %s", GetLastError(), EnumToString(type));
	}

}	

bool	NewBar() {
	static datetime	prevTime	=	0;
	datetime				now		=	iTime(Symbol(), Period(), 0);
	if (now==prevTime)	return(false);
	prevTime	=	now;
	return(true);
}

bool	WaitForHTF(string symbol, ENUM_TIMEFRAMES timeframe) {

	for (int waitCount=9; waitCount>=0; waitCount--) {
		datetime	t	=	iTime(symbol, timeframe, 0);
		int	err	=	GetLastError();
		if (t>0)	return(true);
		Sleep(100);
   }
   return(false);

}

//	Symbol values - also a candidate for common toolbox
double	SymbolAsk()	{	return(SymbolInfoDouble(Symbol(), SYMBOL_ASK));	}
double	SymbolBid()	{	return(SymbolInfoDouble(Symbol(), SYMBOL_BID));	}
