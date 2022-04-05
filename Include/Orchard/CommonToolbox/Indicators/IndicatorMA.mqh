/*

	IndicatorMA.mqh
	Copyright 2021, Orchard Forex 
	https://orchardforex.com 

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://orchardforex.com"
#property version   "1.00"

#include "IndicatorBase.mqh"

/*
	CIndicatorMA
	Usage: CIndicatorMA MA = new CIndicatorMA(symbol, timeframe, period, method, appliedPrice)
*/
class CIndicatorMA : public CIndicatorBase {

private:

protected:

	int				mPeriod;
	int				mShift;
	ENUM_MA_METHOD	mMethod;
	int				mAppliedPrice;
	
public:

	CIndicatorMA() : CIndicatorBase() {};
	CIndicatorMA(string symbol, int timeframe, int period, ENUM_MA_METHOD method, int appliedPrice);
	~CIndicatorMA();

	void			Init(string symbol, int timeframe, int period, ENUM_MA_METHOD method, int appliedPrice);
	
	#ifdef __MQL4__
		double	GetValue(int bufferNumber, int index);
	#endif
	
};

CIndicatorMA::CIndicatorMA(string symbol, int timeframe, int period, ENUM_MA_METHOD method, int appliedPrice)
		: CIndicatorBase() {

	Init(symbol, timeframe, period, method, appliedPrice);
	
}

CIndicatorMA::~CIndicatorMA() {
}

void		CIndicatorMA::Init(string symbol,int timeframe,int period,ENUM_MA_METHOD method,int appliedPrice) {

	//	Only needed for mql4 but no harm for mql5
	mSymbol			=	symbol;
	mTimeframe		=	timeframe;
	mPeriod			=	period;
	mShift			=	0;
	mMethod			=	method;
	mAppliedPrice	=	appliedPrice;
	
	//	This must be set for mql5 only
	#ifdef __MQL5__
		mHandle	=	iMA(symbol, (ENUM_TIMEFRAMES)timeframe, period, 0, method, appliedPrice);
	#endif

	//	Set initialised
	//	I'm not currently using this but I should
	mInitialised		=	true;
		
}

//	This is where the code to call the indicator for MQL4 lives
#ifdef __MQL4__
	double	CIndicatorMA::GetValue(int bufferNumber, int index) {
		double	result	=	iMA(mSymbol, mTimeframe, mPeriod, mShift, mMethod, mAppliedPrice, index);
		return(result);
	}
#endif 


