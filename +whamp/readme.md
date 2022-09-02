## Usage

Each time starting new Matlab session execute in Matlab:

```matlab
irf
```

Now you can use any of the irfu packages.

## Whamp plot distribution function
```matlab
Electrons = struct('m',0,'n',1,'t',1,'a',5,'vd',1,'d',1,'b',0);
whamp.plot_f(Electrons,'km/s')
```

## Constructing a dispersion surface
```matlab
Oxygen = struct('m',16,'n',1,'t',10,'a',5,'vd',1);
Electrons = struct('m',0,'n',1,'t',1);
PlasmaModel = struct('B',100);
PlasmaModel.Species = {Oxygen,Electrons};
InputParameters = struct('fstart',0.04,'kperp',[-3 .3 -1],...
'kpar',[-3 .3 -1],'useLog',1);
Output = whamp.run(PlasmaModel,InputParameters)
surf(log10(Output.kperp),log10(Output.kpar),real(Output.f))
xlabel('p');
ylabel('z');
zlabel('f');
```
