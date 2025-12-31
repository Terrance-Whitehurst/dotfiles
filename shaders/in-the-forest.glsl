#define SHADERTOY

#ifdef SHADERTOY
    #define main() mainImage( out vec4 fragColor, in vec2 fragCoord )
    #define u_canvas iResolution
    #define u_mouse iMouse
    #define u_time iTime
    #define gl_FragCoord fragCoord
    #define gl_FragColor fragColor
	#define texture2D texture
	#define textureCube texture
	#define u_texture0 iChannel0
	#define u_texture1 iChannel1
    #define u_textureVideo0 iChannel0
    #define u_textureVideo1 iChannel1
	#define u_textureCube0 iChannel0
	#define u_textureCube1 iChannel1
#endif

#define SUPER_GRAPHIC_CARD

#ifdef SUPER_GRAPHIC_CARD
	#define SOFT_SHADOW
	#define MODEL_HARD
#endif

float time;
#define FAR 100.
#define ID_NONE -1.

#define ID_GROUND 0.
#define ID_TRUNK 1.
#define ID_BRANCH 2.
#define ID_LEAF 3.

float heightGround(vec2 p) {
	p *= 0.0007;
	TF_ROTATE(p, radians(-53.));
	vec2 H = texture2D(u_texture0, p).rg-0.5;
	return 4.*H.x + H.y*8.;
}

float hash11( float p ) { 
	return fract(sin(p)*5346.1764); 
}

float hash21(vec2 p){
	return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453);
}

float map(vec3 p, inout Object object) {
	vec3 q;
	float d = FAR;
	
	vec3 p0 = p;
	
	object = Object(FAR, ID_NONE, p);

	float CSIZE = 3.;
	vec2 CID = TF_REPLICA(p.xz, CSIZE);
	float rnd = hash21(CID);
	
	//Высота деpева
	float h_trunk = 0.5 + rnd*5.;
	//Высота земли в месте нахождения дерева
	float h_ground_tree = heightGround(CID*CSIZE);
	
	//Ствол
	Object OBJ1 = Object(FAR, ID_TRUNK, p);
	{
		q = p;
		q.y -= h_ground_tree;
		//Максимальный радиус ствола
		float R_trunk_max = h_trunk * 0.01;
		//Радиус ствола уменьшаем к вершине
		float R_trunk = R_trunk_max - q.y*R_trunk_max/h_trunk + 0.0025;
		//Расстояние до ствола
		d = AND(TF_BALL(q.xz, R_trunk), TF_BETWEEN2(q.y, -0.5, h_trunk + 0.1));
		OBJ1.distance = d;
	}
	object = OR(object, OBJ1);
	
	//Ветвь
	float L_branch; //Сохраняем длину ветви
	Object OBJ2 = Object(FAR, ID_BRANCH, p);
	{
		q = p;
		q.y -= h_ground_tree;
		//Шаг групп ветвей по высоте
		float step_branch_group = 0.15;
		//Число групп ветвей
		float count_branch_groups = floor(h_trunk/step_branch_group);
		//Разбиваем пространство на группы ветвей по высоте ствола, ограничиваясь числом групп ветвей
		float id_branch_group = TF_REPLICA_LIMIT(q.y, step_branch_group, 0., count_branch_groups);
		//Разбиваем пространство каждой группы ветвей на сектора и добавляем случайный поворот всей группы
		float id_branch_angle = TF_REPLICA_ANGLE(q.xz, count_branch_groups+3. - id_branch_group, sin(id_branch_group));
		//Максимальная длина ветви
		float L_branch_max = h_trunk*0.3;
		//Длину ветвей уменьшаем к вершине
		L_branch = L_branch_max - (L_branch_max-0.1)/count_branch_groups*id_branch_group;
		//Максимальный радиус ветви
		float R_branch_max = 0.01;
		//Уменьшаем радиус ветви к окончанию
		float R_branch = R_branch_max - q.z*R_branch_max/L_branch;
		//Наклоняем каждую ветку случайным образом
		float rnd2 = hash11(id_branch_angle);
		TF_ROTATE(q.yz, -radians(10.*rnd2));
		//Расстояние до ветви
		d = AND(TF_BALL(q.xy, R_branch), TF_BEFORE(q.z, L_branch));
		OBJ2.distance = d*0.7;
	}
	object = OR(object, OBJ2);
	
	//Иголки
	Object OBJ3 = Object(FAR, 3., p);
	{
		//Шаг групп иголок по длине ветви
		float step_leaf_group = 0.05;
		//Число групп иголок
		float count_leaf_groups = floor(L_branch / step_leaf_group);
		//Разбиваем пространство на группы иголок по длине ветви, ограничиваясь числом групп иголок
		float id_leaf_group = TF_REPLICA_LIMIT(q.z, step_leaf_group, 0., count_leaf_groups);
		//Разбиваем пространство каждой группы иголок на сектора и добавляем случайный поворот всей группы
		float id_leaf_angle = TF_REPLICA_ANGLE(q.xy, 10., sin(id_leaf_group));
		//Длина иголки
		float L_leaf = 0.05;
		//Максимальный радиус иголки
		float R_leaf_max = 0.003;
		//Уменьшаем радиус иголки к окончанию
		float R_leaf = R_leaf_max - q.y*R_leaf_max/L_leaf;
		//Наклоняем каждую иголку одинаково
		TF_ROTATE(q.zy, radians(30.));
		//Расстояние до иголки
		d = AND(TF_BALL(q.xz, R_leaf), TF_BEFORE(q.y, L_leaf));
		OBJ3.distance = d*0.7;
	}
	object = OR(object, OBJ3);

	//Пни
	#if 0
		if (rnd<0.6 && rnd>0.3) {
			q = p;
			q.y -= h_ground_tree;
			d = TF_BEFORE(q.y, -0.25);
			object.distance = AND(object.distance, d);
		}
	#endif

	//Земля
	Object OBJ0 = Object(FAR, ID_GROUND, p);
	{
		q = p0;
		float h = -0.5 + heightGround(q.xz);
		d = TF_BEFORE(q.y, h);
		OBJ0.distance = d*0.7;
	}
	object = OR(object, OBJ0, 0.1);

    return object.distance;
}

float map ( in vec3 p ) {
	Object object;
	return map (p, object);
}

vec3 mapNormal (vec3 p, float eps) {
	vec2 e = vec2 (eps, -eps);
	vec4 v = vec4 (
		map (p + e.xxx), 
		map (p + e.xyy),
	 	map (p + e.yxy), 
		map (p + e.yyx)
	);
	return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * vec3 (v.y, v.z, v.w));
}

float rayMarch(inout Ray ray) {
	ray.distance = ray.near;
	float steps = 1.;
	for (float i = 0.; i < 200.; ++i) {
		ray.position = ray.origin + ray.direction * ray.distance;
		ray.object.distance = map(ray.position, ray.object);
		//if (i==0.) ray.swing = sign(ray.object.distance);//Внутри или снаоужи
		ray.hit = abs(ray.object.distance) < ray.epsilon;
		ray.distance += ray.object.distance*ray.swing;
		steps++;
		if (ray.hit || ray.distance>ray.far || steps>ray.steps) break;
	}
	return steps;
}

float softShadow( Ray ray, float k ) {
    float shade = 1.0;
    ray.distance = ray.near;    
	float steps = 1.;
    for ( int i = 0; i < 50; i++ ) {
		ray.position = ray.origin + ray.direction * ray.distance;
        ray.object.distance = map(ray.position);
        shade = min( shade, smoothstep( 0.0, 1.0, k * ray.object.distance / ray.distance)); 
		ray.hit = abs(ray.object.distance) < ray.epsilon;
        ray.distance += min( ray.object.distance, ray.far / ray.steps * 2. ); 
		steps++;
		if (ray.hit || ray.distance>ray.far || steps>ray.steps) break;
    }
	#if 0
		return shade;
	#else
    	return min( max( shade, 0.0 ) + 0.5, 1.0 ); 
	#endif
}

float softShadow(Ray ray, vec3 lightDir, float k) {
	ray.origin = ray.position;
	ray.direction = lightDir;
	return softShadow(ray, k);
}

//Интерференция 20 точек двигающихся по кругу
vec3 bgColor(vec3 rd) {
	rd.x -= -0.3+0.1;
    float bright = u_canvas.x*0.5;
    vec3 p;
    vec3 a = vec3(1.0, 1.5, 2.0);
    vec3 re = vec3(0);
    vec3 im = vec3(0);
    for (float i=0.; i<20.; i++) {
        #if 0
            p = vec3(  0.05 - 0.035,0.,1.);
        #else
            p = vec3(0,0,1);
        #endif
        p.x *= u_canvas.x/u_canvas.y;
		TF_ROTATE(p.xy, (time+10.)*0.05*i);
        float r = length(rd - p) * u_canvas.x;
        re += cos(r * a) / r;
        im += sin(r * a) / r;
    }
   vec3 col = bright * (re*re + im*im);// * u_canvas.x;
   col = clamp(col, 0.,1.);
   return col;
}

vec3 lighting(Ray ray, vec3 lightDir, vec3 mCol, vec3 bgCol) {
	float sh = 1.;
	#ifdef SOFT_SHADOW
		ray.far = 10.;
		sh = softShadow(ray, lightDir, 32.);
	#endif
	float diff = max(dot(ray.normal, lightDir), 0.);
	float back = max(dot(ray.normal, normalize(vec3(-lightDir.x, lightDir.y, -lightDir.z))), 0.);
	float spec = pow(max(dot(reflect(ray.direction,ray.normal),lightDir), 0.),64.);
	return mCol*(0.2 + 0.2*back + 0.8*diff*sh) + spec*bgCol*sh;
}

vec3 getMaterial(Ray ray) {
	vec3 mCol;
	if (ray.object.id==ID_GROUND) {
		mCol = vec3(1);
	} else if (ray.object.id==ID_TRUNK) {
		mCol = vec3(1,0.5,0);
	} else if (ray.object.id==ID_BRANCH) {
		mCol = vec3(1,0.5,0);
	} else if (ray.object.id==ID_LEAF) {
		mCol = vec3(0.2,1,0.2);
	}
	return mCol;
}

vec3 render(Ray ray) {
    vec3 col = vec3(0);
	vec3 bgCol = bgColor(ray.direction);

    rayMarch(ray);
    
    if (ray.distance<FAR) {
		ray.normal = mapNormal(ray.position, 0.01);
		vec3 mCol = getMaterial(ray);
    
		vec3 lightDir = normalize(vec3(-1, 10., 5.));
		col = lighting(ray, lightDir, mCol, bgCol);
		//Туман
		float fogStart = 20.;
		vec3 fogColor = bgCol;
		col = mix(col, fogColor, 1.-exp(-pow(ray.distance/fogStart, 3.)));
    } else {
		col = bgCol;
	}

	return col;
}

//https://www.shadertoy.com/view/XtBfzw
float snow(vec2 uv,float scale) {
	float w=smoothstep(1.,0.,-uv.y*(scale/10.));
	if(w<.1)return 0.;
	uv+=u_time/scale;
	uv.y+=u_time*2./scale;
	uv.x+=sin(uv.y+u_time*.5)/scale;
	uv*=scale;
	vec2 s=floor(uv),f=fract(uv),p;
	float k=3.,d;
	p=.5+.35*sin(11.*fract(sin((s+p+scale)*mat2(7,3,6,5))*5.))-f;
	d=length(p);
	k=min(d,k);
	k=smoothstep(0.,k,sin(f.x+f.y)*0.01);
    return k*w;
}

void main() {
	time = u_time;

	float aspect = u_canvas.x/u_canvas.y;
	vec2 uv = gl_FragCoord.xy/u_canvas.xy - 0.5;
	
	vec2 mouse = u_mouse.xy / u_canvas.xy - 0.5;
	if (u_mouse.xy==vec2(0)) mouse = vec2(0);

	vec2 ori = vec2(
		u_mouse.z==0. ? radians(-5.) : radians(-5.) + mouse.y*PI*2.,
		u_mouse.z==0. ? 0.0*time : 0.0*time + mouse.x*PI*2.
	);
	//ori.x = clamp(ori.x, -radians(90.), radians(90.));

	Camera cam;
	{
		cam.fov     = 45.;
		cam.aspect  = aspect;
		cam.origin  = vec3(-1.5, 2., time*0.5);
		cam.origin.y += heightGround(cam.origin.xz);
		cam.target	= cam.origin + vec3(0, 0, 1);
		cam.up 		= vec3(0,1,0);
		cam.vMat 	= TF_ROTATE_Y(ori.y) * TF_ROTATE_X(ori.x);
		cam.mMat	= mat3(1);//TF_ROTATE_Y(ori.y) * TF_ROTATE_X(ori.x);
	}
	
	Ray ray = lookAt(uv, cam);
	{
		ray.near 	= 0.01;
		ray.far  	= FAR;
		ray.epsilon = 0.001;
		ray.swing	= 1.;
		ray.steps 	= 200.;
	}
	vec3 ro = ray.origin;
	vec3 rd = ray.direction;

	vec3 col = render(ray);
	
	//Снег
	float c = smoothstep(1.,0.3,clamp(uv.y*.3+.8,0.,.75));
	c += snow(uv,30.)*.3;
	c += snow(uv,20.)*.5;
	c += snow(uv,15.)*.8;
	c += snow(uv,10.);
	c += snow(uv,8.);
	c += snow(uv,6.);
	c += snow(uv,5.);
	col += vec3(c);
	
    gl_FragColor = vec4(col*0.7,1.0);
}