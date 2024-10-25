//import 'dart:ffi';

import 'package:flutter/material.dart';
import 'app.dart';

void main()
{
  runApp(const MyApp());
}

/*
General notes:
- User selects current driver before laptimes are recieved
- Start/Stop for recieving data
- displays laptimes as they come in

Todo:
- Laptimes:
	- Start/Stop button
	- design general format
	- laptimeData class, should use hash map to store 
- LiveTelem:
	- Refactor json reading -> display functionality for indexing data with display names
	- do some string checking
	- methods to fix:
		- figure it out
*/