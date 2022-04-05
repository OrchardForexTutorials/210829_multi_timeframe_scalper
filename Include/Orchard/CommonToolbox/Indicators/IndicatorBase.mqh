/*

	IndicatorBase.mqh
	Copyright 2021, Orchard Forex 
	https://orchardforex.com 

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link      "https://orchardforex.com"
#property version   "1.00"

class CIndicatorBase {

private:

protected:

	//	Control values
	bool		mInitialised;
	
	//	Values used by MQL4
	string	mSymbol;
	int		mTimeframe;

	//	Handle and buffer used by MQL5	
	int		mHandle;
	double	mBuffer[];

public:

   CIndicatorBase();
   ~CIndicatorBase();
   
   bool		IsValid()	{	return(mHandle!=INVALID_HANDLE);	}
	int		GetArray(int bufferNumber, int start, int count, double &arr[]);	//	Retrieve an array of values
	virtual double	GetValue(int bufferNumber, int index);								//	Retrieve a single value
	virtual double	GetValue(int index)	{	return(GetValue(0,index));	}			//	Some indicators have only 1 buffer

   
};

CIndicatorBase::CIndicatorBase() {

	//	Set initialised to false, the child classes should fix this
	mInitialised	=	false;
	
	//	Init the common values, basically to say this hasn't been initialised
	mSymbol			=	Symbol();
	mTimeframe		=	Period();
	
	//	child classes will set the handle
	mHandle	=	0;
	ArraySetAsSeries(mBuffer, true);
	
}

CIndicatorBase::~CIndicatorBase() {

	#ifdef __MQL5__
		IndicatorRelease(mHandle);
	#endif 
	
}

#ifdef __MQL4__

	//	Just a blank function for the base class
	double	CIndicatorBase::GetValue(int bufferNumber, int index) {
		return(0);
	}

	//	For mql4 we have to build up the array from individual calls
	int		CIndicatorBase::GetArray(int bufferNumber,int start,int count,double &arr[]) {
	
		ArraySetAsSeries(arr, true);
		ArrayResize(arr, count);
		for (int i=0; i<count; i++) {
			arr[i]	=	GetValue(bufferNumber, i+start);
		}
		return(count);
		
	}

#endif

#ifdef __MQL5__

	//	In mql5 get the array first then pull a single value
	//	Could be done by calling GetArray but there is no need
	double	CIndicatorBase::GetValue(int bufferNumber, int index) {
	
		int	result	=	CopyBuffer(mHandle, bufferNumber, index, 1, mBuffer);
		if (result<1) return(0);
		return(mBuffer[0]);
		
	}

	//	For mql5 the array is the natural return	
	int		CIndicatorBase::GetArray(int bufferNumber,int start,int count,double &arr[]) {
	
		ArraySetAsSeries(arr, true);
		int	result	=	CopyBuffer(mHandle, bufferNumber, start, count, arr);
		return(result);
		
	}

#endif
