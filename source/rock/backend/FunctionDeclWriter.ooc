import ../middle/[FunctionDecl, TypeDecl, ClassDecl, Argument, Type]
import Skeleton
include stdint

ArgsWriteMode: cover from Int32 {}

ArgsWriteModes: class {
    FULL = 1,
    NAMES_ONLY = 2,
    TYPES_ONLY = 3 : static const Int32
}

FunctionDeclWriter: abstract class extends Skeleton {
    
    write: static func ~function (this: This, fDecl: FunctionDecl) {
        //"|| Writing function %s" format(fDecl name) println()
        
        if(fDecl isExtern()) return
        
        // header
        current = hw
        current nl()
        writeFuncPrototype(this, fDecl)
        current app(';')
        
        // source
        current = cw
        current nl(). nl()
        writeFuncPrototype(this, fDecl)
        current app(" {"). tab()
        for(stat in fDecl body) {
            writeLine(stat)
        }
        current untab(). nl(). app("}")
    }
    
    /** Write the name of a function, with its suffix, and prefixed by its owner if any */
    writeFullName: static func (this: This, fDecl: FunctionDecl) {

        //printf("Writing full name of %s, owner = %s\n", fDecl name, fDecl owner ? fDecl owner toString() : "(nil)")
        if(fDecl isExtern() && !fDecl externName isEmpty()) {
            current app(fDecl externName)
        } else {
            if(fDecl isMember()) {
                current app(fDecl owner getExternName()). app('_')
            }
            writeSuffixedName(this, fDecl)
        }
    }
    
    /** Write the name of a function, with its suffix */
    writeSuffixedName: static func (this: This, fDecl: FunctionDecl) {
        current app(fDecl name)
        if(fDecl suffix) {
            current app("_"). app(fDecl suffix)
        }
    }
    
    /** Write the arguments of a function (default params) */
    writeFuncArgs: static func ~defaults (this: This, fDecl: FunctionDecl) {
        writeFuncArgs(this, fDecl, ArgsWriteModes FULL, null)
    }
    
    /**
     * Write the arguments of a function
     * 
     * @param baseType For covers, the 'this' must be casted otherwise
     * the C compiler complains about incompatible pointer types. Or at
     * least that's my guess as to its utility =)
     * 
     * @see FunctionCallWriter
     */
    writeFuncArgs: static func (this: This, fDecl: FunctionDecl, mode: ArgsWriteMode, baseType: TypeDecl) {
        
        current app('(')
        isFirst := true

        /* Step 1 : write this, if any */
        iter := fDecl args iterator() as Iterator<Argument>
        if(fDecl isMember()) {
            isFirst = false
            
            type := fDecl owner thisDecl getType()
                        
            match mode {
                case ArgsWriteModes NAMES_ONLY =>
                    if(baseType) {
                        current app("("). app(baseType getNonMeta() getType()). app(")")
                    }
                    current app("this")
                case ArgsWriteModes TYPES_ONLY =>
                    current app(type)
                case =>
                    current app(type). app(" this")
            }
        }
        
        /* Step 2 : write generic type args */
        for(typeArg in fDecl typeArgs) {
            if(!isFirst) current app(", ")
            else isFirst = false
            current app(typeArg)
        }
        
        /* Step 3 : write real args */
        while(iter hasNext()) {
            arg := iter next()
            //"Writing arg %s" format(arg toString()) println()
            if(!isFirst) current app(", ")
            else isFirst = false
            
            match mode {
                case ArgsWriteModes NAMES_ONLY =>
                    current app(arg name)
                case ArgsWriteModes TYPES_ONLY =>
                    {
                        if(arg instanceOf(VarArg)) {
                            current app("...")
                        } else {
                            current app(arg type)
                        }
                    }
                case =>
                    current app(arg)
            }
        }
        
        /* Step 4 : Write exception handling arguments */
        // TODO
        
        current app(')')
        
    }
    
    writeFuncPrototype: static func ~defaults (this: This, fDecl: FunctionDecl) {
        writeFuncPrototype(this, fDecl, null)
    }
    
    
    writeFuncPrototype: static func (this: This, fDecl: FunctionDecl, additionalSuffix: String) {
        
        //"|| Writing prototype of fDecl %s" format(fDecl name) println()
        
        // TODO inline member functions don't work yet anyway.
        //if(functionDecl isInline()) cgen.current.append("inline ")
            
        // TODO add function pointers and generics
        current app(fDecl returnType). app(' ')
        
        writeFullName(this, fDecl)
        if(additionalSuffix) current app(additionalSuffix)
        
        writeFuncArgs(this, fDecl)
        
        // TODO add function pointers
        /*if(returnType instanceof FuncType) {
            TypeWriter writeFuncPointerEnd((FunctionDecl) returnType.getRef(), cgen)
        }*/
        
    }    
    
}

