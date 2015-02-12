RuberTooth
========================

A complete Ruby porting of the [ubertooth](http://ubertooth.sourceforge.net/)
libraries and utilities.

Motivations
---

Ubertooth Python libraries are incomplete in the best case, only a few features
are implemented from their native counterparts.  
Moreover compiling and installing native libraries can be a painful process,
especially under latest versions of OS X.

This Ruby porting directly communicates with the UberTooth device using USB, it
only depends on the **libusb** and **bindata** gems that can be easily installed
executing:

    cd rubertooth && bundle install


This is also an easier way to implement your own scripts using UberTooth.

Oh and yes, I **hate** Python.

License
---

Released under the BSD license.  
Copyright &copy; 2015, Simone Margaritelli
<evilsocket@gmail.com>  

<http://www.evilsocket.net/>  
All rights reserved.
