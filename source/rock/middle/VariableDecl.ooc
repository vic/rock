import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl, VariableAccess,
       Node, ClassDecl, FunctionCall
import tinker/[Response, Resolver, Trail]

VariableDecl: class extends Declaration {

    name: String
    type: Type
    expr: Expression
    owner: TypeDecl

    isConst := false
    isStatic := false
    externName: String = null
    
    init: func ~vDecl (.type, .name, .token) {
        this(type, name, null, token)
    }
    
    init: func ~vDeclWithAtom (=type, =name, =expr, .token) {
        super(token)
    }
    
    accept: func (visitor: Visitor) {
        visitor visitVariableDecl(this)
    }

    getType: func -> Type { type }
    
    getName: func -> String { name }
    
    toString: func -> String {
        "%s : %s%s" format(
            name,
            type ? type toString() : "<unknown type>",
            expr ? " = " + expr toString() : ""
        )
    }
    
    setExpr: func (=expr) {}
    setStatic: func (=isStatic) {}
    
    isExtern: func -> Bool { externName != null }
    
    isExternWithName: func -> Bool {
        (externName != null) && !(externName isEmpty())
    }
    
    resolveAccess: func (access: VariableAccess) {
        if(name == access name) {
            access suggest(this)
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)

        //printf("Resolving variable decl %s\n", toString());
        
        if(expr) {
            response := expr resolve(trail, res)
            //printf("response of expr = %s\n", response toString())
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }

        if(!type) {
            //"coool! we're gonna have to infer it!" println()
            type = expr getType()
            if(!type) {
                //"Still null, looping..." println()
                return Responses LOOP
            }
        }
        
        {
            response := type resolve(trail, res)
            //printf("response of type = %s\n", response toString())
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        
        trail pop(this)
        
        {
            parent := trail peek()
            if(!parent isScope() && !parent instanceOf(TypeDecl)) {
                //println("uh oh the parent of " + toString() + " isn't a scope but a " + parent class name)
                idx := trail findScope()
                result := trail get(idx) addBefore(trail get(idx + 1), this)
                trail peek() replace(this, VariableAccess new(this, token))
                return Responses LOOP
            } 
        }
        
        if(expr != null && expr instanceOf(FunctionCall)) {
            fCall := expr as FunctionCall
            fDecl := fCall getRef()
            if(!fDecl) return Responses LOOP
            if(!fDecl getReturnType() isResolved()) return Responses LOOP
            
            //println("got decl rhs a " + fCall toString())
            if(fDecl getReturnType() isGeneric()) {
                fCall setReturnArg(VariableAccess new(this, token))
                //println("Adding add a " + fCall toString() + " after a " + toString() + ", trail = " + trail toString())
                result := trail addAfterInScope(this, fCall)
                if(!result) {
                    token throwError("Couldn't add a " + fCall toString() + " after a " + toString() + ", trail = " + trail toString())
                }
                expr = null
            }
        }
        
        return Responses OK
        
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case type => type = kiddo; true
            case => false
        }
    }

}
