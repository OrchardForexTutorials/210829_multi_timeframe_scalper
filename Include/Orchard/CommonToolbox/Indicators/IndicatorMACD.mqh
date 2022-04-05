/*

	IndicatorMACD.mqh
	Copyright 2021, Orchard Forex 
	https://orchardforex.com 

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://orchardforex.com"
#property version   "1.00"

#include "IndicatorBase.mqh"

/*
	CIndicatorMACD
	Usage: CIndicatorMACD MACD = new CIndicatorMACD(symbol, timeframe, fastPeriod, slowPeriod, signalPeriod, appliedPrice)
*/
class CIndicatorMACD : public CIndicatorBase {

private:

protected:

	int	mFastPeriod;
	int	mSlowPeriod;
	int	mSignalPeriod;
	int	mAppliedPrice;
	
public:

	CIndicatorMACD()	:	CIndicatorBase()	{};
	CIndicatorMACD(string symbol, int timeframe, int fastPeriod, int slowPeriod, int signalPeriod, int appliedPrice);
	~CIndicatorMACD();

	void			Init(string symbol, int timeframe, int fastPeriod, int slowPeriod, int signalPeriod, int appliedPrice);
	
	#ifdef __MQL4__
		double	GetValue(int bufferNumber, int index);
	#endif
	
};

CIndicatorMACD::CIndicatorMACD(string symbol, int timeframe, int fastPeriod, int slowPeriod, int signalPeriod, int appliedPrice)
		: CIndicatorBase() {
		
	Init(symbol, timeframe, fastPeriod, slowPeriod, signalPeriod, appliedPrice);
	
}

void		CIndicatorMACD::Init(string symbol,int timeframe,int fastPeriod,int slowPeriod,int signalPeriod,int appliedPrice) {

	//	Only needed for mql4 but no harm for mql5
	mSymbol			=	symbol;
	mTimeframe		=	timeframe;
	mFastPeriod		=	fastPeriod;
	mSlowPeriod		=	slowPeriod;
	mSignalPeriod	=	signalPeriod;
	mAppliedPrice	=	appliedPrice;
	
	#ifdef __MQL5__
		mHandle	=	iMACD(symbol, (ENUM_TIMEFRAMES)timeframe, fastPeriod, slowPeriod, signalPeriod, appliedPrice);
	#endif
	
	//	Set initialised
	//	I'm not currently using this but I should
	mInitialised		=	true;

}

CIndicatorMACD::~CIndicatorMACD() {
}

#ifdef __MQL4__
	double	CIndicatorMACD::GetValue(int bufferNumber, int index) {
		double	result	=	iMACD(mSymbol, mTimeframe, mFastPeriod, mSlowPeriod, mSignalPeriod, mAppliedPrice, bufferNumber, index);
		return(result);
	}
#endif 


