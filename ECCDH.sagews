︠2b9651fc-3ca2-4ecc-b465-3df7f83c9375︠
# THE SETUP
#
# We first specify the domain parameters (p,a,b,G,n,h); p is a prime, a,b are the coefficients of the elliptic curve E, G is a fixed point on E, n is the order of G, and h is the cofactor of n

p = next_prime(321456789876)
a = -3024
b = 46224
E = EllipticCurve(GF(p),[a,b]) #my favourite elliptic curve, 389a1, smallest curve of rank 2 over Q (ordered by conductor)

# We now choose a random point on E to serve as G

GX = GF(p).random_element()
GY = GX^3 + a*GX + b
while not GY.is_square():
    GX = GF(p).random_element()
    GY = GX^3 + a*GX + b
G = E.lift_x(GX)
n = G.order()
h = E.order()/n

# So now Alice and Bob will choose their public and private keys

dA = randrange(1,n) #of course, Alice is free to choose whatever number she wants as her Private key
HA = dA * G         #Alice's public key

dB = randrange(1,n) #ditto for Bob
HB = dB * G         #Bob's public key

# Next, Alice and Bob will create their shared secret, allowing them to securely encrypt their messages

S = dA * HB

︡24715f8f-5a7d-48f3-978a-890898ab7679︡{"done":true}︡
︠b837804e-f757-45c9-b692-983a03753510o︠
# So now we need a character encoding scheme, to convert messages into numbers, and back again. Here we give a simple, ad-hoc method, essentially ASCII, but shifted; a = 1, b = 2, ... z = 26, except j != 10, rather j=27, and t != 20, rather t = 28. Space between words is '00', and '0' signifies "go to the next character". The exceptions for j and t were made to distinguish between, e.g., "a ja" and "ja a" (which would otherwise both have the same value of 1001001). Also, i've kept this simple, so no capital letters, and only some special characters like !,?,@,/).

def CharacterNumber(foo):
    if foo == 'j':
        return '27'
    elif foo == 't':
        return '28'
    elif foo == '.':
        return '29'
    elif foo == '!':
        return '31'
    elif foo == '@':
        return '32'
    elif foo == '/':
        return '33'
    elif foo == '?':
        return '34'
    elif foo == ',':
        return '35'
    elif foo == '1':
        return '36'
    elif foo == '2':
        return '37'
    elif foo == '3':
        return '38'
    elif foo == '4':
        return '39'
    elif foo == '5':
        return '41'
    elif foo == '6':
        return '42'
    elif foo == '7':
        return '43'
    elif foo == '8':
        return '44'
    elif foo == '9':
        return '45'
    elif foo == '0':
        return '46'
    elif foo == '-':
        return '47'
    else:
        return str(ord(foo)-96)

def NumberCharacter(foo):
    if foo == '27':
        return 'j'
    elif foo == '28':
        return 't'
    elif foo == '29':
        return '.'
    elif foo == '31':
        return '!'
    elif foo == '32':
        return '@'
    elif foo == '33':
        return '/'
    elif foo == '34':
        return '?'
    elif foo == '35':
        return ','
    elif foo == '36':
        return '1'
    elif foo == '37':
        return '2'
    elif foo == '38':
        return '3'
    elif foo == '39':
        return '4'
    elif foo == '41':
        return '5'
    elif foo == '42':
        return '6'
    elif foo == '43':
        return '7'
    elif foo == '44':
        return '8'
    elif foo == '45':
        return '9'
    elif foo == '46':
        return '0'
    elif foo == '47':
        return '-'
    else:
        return chr(int(foo)+96)
    
def MessageNumber(foo):
    Len = len(foo)
    i=1
    Output = CharacterNumber(foo[0])
    while(i < Len):
       if foo[i] == ' ':
           Output += '0'
       else:
           Output += '0' + CharacterNumber(foo[i])
       i=i+1
    return ZZ(int(Output))

def NumberMessage(foo):
    Output = ''
    i=0
    while(foo != ''):
        Len = len(foo)
        while(i < Len and foo[i] != '0'):
            i=i+1
        Output += NumberCharacter(foo[:i])
        foo = foo[i+1:]
        if foo != '' and foo[0]=='0':
            Output += ' '
            foo = foo[1:]
        i=0
    return Output
︡fb50d803-2e6a-44c2-b115-adbe510b67e7︡{"done":true}︡
︠3c6f6487-ab96-4efa-b24f-4fc552cfa773s︠
# Let's give that a spin, shall we?

MessageNumber("hi bob, alice here. where are you?")

NumberMessage("10280028080500130150220905019")
︡b0ffabea-b85f-48fc-8ebb-06f00c0442ec︡{"stdout":"8090020150203500101209030500805018050290023080501805001018050025015021034\n"}︡{"stdout":"'at the movies'\n"}︡{"done":true}︡
︠98072574-e6b1-46f9-b179-9740ae611d42s︠
# OK, so now let's suppose that Alice wants to send that message securely to Bob. Having converted it into a number, she now needs to convert it into a point on the elliptic curve E. There's no canonical way of doing this, so here I do the first thing that came to my head; take the p-adic expansion of the number, and let the coefficients define an element in the corresponding finite extension of GF(p); this will then be the x-coordinate of the point on E, defined over said finite extension of GF(p). It will then have to be tweaked until the y-coordinate is also defined over this extension (and not over a quadratic). This tweaking factor, as well as the degree of the extension, must be shipped along with the encrypted message


def VectorModToVector(test): #this function needed for technical reasons
    Output = []
    for i in test:
        Output.append(ZZ(i))
    return Output

def NumberPoint(Number): # this is the main function
    nprime = 1
    while(Number > p^nprime):
        nprime+=1
    
    N = nprime
    L.<s> = GF(p^N)
    PAdicRing = Zp(p, prec = 1 + nprime, type = 'fixed-mod', print_mode = 'series')
    MCoefficients = PAdicRing(Number).list()
    
    XCoordinate = 0
    for idx,val in enumerate(MCoefficients):
        XCoordinate += val*s^(idx)
        
    Thingy = L(XCoordinate^3 + a*XCoordinate + b)
    NewXCoordinate = XCoordinate
    Tweak = 1
    while not Thingy.is_square():
        Tweak = L.random_element()
        if Tweak != L(0):
            NewXCoordinate = XCoordinate*Tweak
            Thingy = NewXCoordinate^3 + a*NewXCoordinate + b
    
    EExt = E.base_extend(L)
    SExt = EExt(S)
    
    ThePoint = (EExt.lift_x(NewXCoordinate) + SExt).dehomogenize(2)
    
    ThePoint = (VectorModToVector(vector(ThePoint[0])),VectorModToVector(vector(ThePoint[1])))
    
    if Tweak not in ZZ:
        Tweak = VectorModToVector(vector(Tweak))
    
    return (ThePoint,N,Tweak)


︡b9242e2e-aaea-4920-8432-14b2bfe1fea4︡{"done":true}︡
︠2324be84-3400-4b6a-842f-2098584a25a3s︠
# So what does Alice finally send to Bob?

def MessagePoint(Message):
    return NumberPoint(MessageNumber(Message))

MessagePoint("hi bob, alice here. where are you?")
︡9e3541bd-6bba-4e51-8f2d-5ba43d43d78c︡{"stdout":"(([319845102371, 57454937697, 29198941433, 231070946850, 180120629743, 188663709222, 5780236955], [107659197217, 12702229585, 114860877157, 18222454894, 64492855981, 249101670176, 285135510085]), 7, [20516227883, 313926125837, 85207855702, 41799652861, 170633330261, 221103741944, 13438125046])\n"}︡{"done":true}︡
︠47accaf1-3e98-4983-995b-2e4ab3f1a968s︠
# Having received this message, Bob works backwards - subtracts the shared secret, uses Tweak to untweak the message, and recovers the number corresponding to the message from the x-coordinate of the resulting point. He then uses the above NumberMessage to get the message. "Silver" corresponds to "Tweak"

def PointNumber(Input,N,Silver):
    L.<s> = GF(p^N)
    
    EExt = E.base_extend(L)
    SExt = EExt(S)
    
    TheFirstCoordinate = 0
    RunningOver = enumerate(Input[0])
    for idx,val in RunningOver:
        TheFirstCoordinate += val*s^idx
        
    TheSecondCoordinate = 0
    RunningOver = enumerate(Input[1])
    for idx,val in RunningOver:
        TheSecondCoordinate += val*s^idx
    
    Silvery = 0 
    
    if Silver in ZZ:
        Silvery = Silver
    else:
        RunningOver = enumerate(Silver)
        for idx,val in RunningOver:
            Silvery += val*s^idx
        
    Output = EExt((TheFirstCoordinate,TheSecondCoordinate)) - SExt
    
    Output = Output[0]/Silvery
    Ring.<s> = ZZ[]
    Output = Ring(Output)
    
    MCoefficients = Output.list()
    
    Output = 0
    for idx,val in enumerate(MCoefficients):
        Output += val*p^(idx)
        
    return Output

def PointMessage(TheInput,N,Silver):
    return NumberMessage(str(PointNumber(TheInput,N,Silver)))


︡36e5ffb9-2c6b-4bcd-b146-9ab2af89b106︡{"done":true}︡
︠10d39a18-e9fc-4c9d-a51a-ac305c8d670a︠
# So now Bob can finally read the message he received from Alice

PointMessage(([319845102371, 57454937697, 29198941433, 231070946850, 180120629743, 188663709222, 5780236955], [107659197217, 12702229585, 114860877157, 18222454894, 64492855981, 249101670176, 285135510085]), 7, [20516227883, 313926125837, 85207855702, 41799652861, 170633330261, 221103741944, 13438125046])
︡74f67d26-ccaf-4366-a314-825a76dc0e8e︡{"stdout":"'hi bob, alice here. where are you?'\n"}︡{"done":true}︡
︠a652c06f-b424-482b-a132-6c3148894b65s︠
# Let's just do one more test

MessagePoint("triviality is the profoundest truth")
︡f1dcb0c4-aa0a-4e81-9d14-244f28572b9f︡{"stdout":"verbose 0 (3370: multi_polynomial_ideal.py, groebner_basis) Warning: falling back to very slow toy implementation.\n"}︡{"stdout":"(([109121970763, 219822123883, 89208767498, 144000159475, 85275047525, 90537606528, 181305719297, 139231123225], [53951509531, 36895382468, 78496450688, 290069894227, 66710311949, 77377790908, 238932670422, 270447217264]), 8, [41091363603, 208241833170, 271623307872, 11570217824, 135149020313, 300340433480, 80457947645, 185748559774])\n"}︡{"done":true}︡
︠d845ecf6-1ab2-4154-bc16-dc6a5ee60385s︠
PointMessage(([109121970763, 219822123883, 89208767498, 144000159475, 85275047525, 90537606528, 181305719297, 139231123225], [53951509531, 36895382468, 78496450688, 290069894227, 66710311949, 77377790908, 238932670422, 270447217264]), 8, [41091363603, 208241833170, 271623307872, 11570217824, 135149020313, 300340433480, 80457947645, 185748559774])
︡04a6e2a5-7f31-4287-b0d6-de60bc5dd0a2︡{"stdout":"'triviality is the profoundest truth'\n"}︡{"done":true}︡
︠1fcd9038-a5bc-49ff-9407-d76a5ce6fb28︠

︠503035ef-43d9-401e-b65a-6013ddea307e︠









